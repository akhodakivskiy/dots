crypto = require 'crypto'

class Session
  constructor: (@_socket, @_store) ->
    @_props = [ '_socket', '_store', '_props' ]
    @_generate @_socket.handshake?['dots.sid']
  
  _generate: (id, data) ->
    if not id
      id = generateId(@_socket, @_store)
    if data instanceof Object
      for key, value of data
        this[key] = value
    @id   = id
    @age  = @_store.maxAge
    @date = new Date
  
  _clear: ->
    for prop of this
      if prop not in @_props and this.hasOwnProperty prop
        delete this.prop

  _obj: ->
    obj = {}
    for prop, value of this
      if prop not in @_props and this.hasOwnProperty prop
        obj[prop] = value 

    obj

  load: (cb) ->
    @_store.get @id, (err, data) =>
      @_clear()
      @_generate @id, data
      cb? err

  save: (cb) ->
    @_store.set @id, @_obj(), (err) =>
      cb? err

  clear: (cb) ->
    @_store.del @id, (err) =>
      @_clear()
      @_generate @id, {}
      cb err

generateId = (socket, store) -> 
  crypto
    .createHmac('sha1', store.secret)
    .update(socket.id)
    .digest('base64')
    .replace( /\=*$/ , '')


uid = (len) -> 
  buf = []
  chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
  charlen = chars.length

  for i in [0..len]
    buf.push(chars[getRandomInt(0, charlen - 1)])

  buf.join('');

module.exports = Session

