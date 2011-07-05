redis   = require 'redis'
util    = require 'util'
crypto  = require 'crypto'
check   = require('validator').check
redobj  = require '../../vendor/redobj'
config  = require '../../config'

hash = (password) ->
  crypto
    .createHmac('sha1', config.secret)
    .update(password)
    .digest('base64')
    .replace( /\=*$/ , '')

class UserModel extends redobj.Redobj
  constructor: (@client) ->
    keys = 
      username:     redobj.string('backref')
      password:     redobj.string()
      registerDate: redobj.string()

    super @client, 'user', keys

UserModel::authenticate = (username, password, cb) ->
  if not check(username).isAlphanumeric()
    cb 'Authentication failed: username must be alpha-numeric string'
  else
    @findOne { username: username }, (err, user) =>
      if err 
        cb 'Authentication failed: internal error'
      else if user
        if user.password != hash(password)    
          cb 'Authentication failed: wrong password'
        else
          cb null, user
      else
        user = 
          username: username
          password: hash(password)
          registerDate: new Date
        @set user, cb

UserModel::changePassword = (username, oldPassword, newPassword, cb) ->
  @authenticate username, oldPassword, (err, user) =>
    if err then cb err
    else
      user.password = hash(newPassword)
      @set user, ['password'], cb

UserModel::nextGuest = (cb) ->
  @client.incr "ids:#{@name}:guest:next", (err, val) ->
    cb? err, "guest#{val}"

module.exports = (client) -> new UserModel client
