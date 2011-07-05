vows    = require 'vows'
assert  = require 'assert'
redis   = require 'redis'
config  = require '../config'

client = redis.createClient(config.redis?.host, config.redis?.port)
client.auth config.redis.auth
client.select 15
client.flushdb()

model = require('../dots/models/user')(client)
suite = vows.describe 'user model'

assert.user = (user, username) ->
  assert.isNotNull  user
  assert.equal      user.username, username
  assert.isNotNull  user.registerDate

suite.addBatch
  'authenticate with registration':
    topic: ->
      model.authenticate 'username', 'password', this.callback
      return
    'registered': (err, user) ->
      assert.isNull err
      assert.user   user, 'username'
    'authenticate with login': 
      topic: (user) ->
        model.authenticate 'username', 'password', this.callback
        return
      'logged in': (err, user) ->
        assert.isNull err
        assert.user   user, 'username'
    'authenticate with wrong password': 
      topic: (user) ->
        model.authenticate 'username', 'wrong password', this.callback
        return
      'logged in': (err, user) ->
        assert.isNotNull    err
        assert.isUndefined  user

  'password change after registration':
    topic: ->
      model.authenticate 'username2', 'password2', this.callback
      return
    'registered':
      topic: ->
        model.changePassword 'username2', 'password2', 'password3', this.callback
      'password changed': (err, user) ->
        assert.isNull err
        assert.user user, 'username2'
      'verify password change':
        topic: ->
          model.authenticate 'username2', 'password3', this.callback
        'verified': (err, user) ->
          assert.isNull err
          assert.user user, 'username2'

  'next guest':
    topic: ->
      model.nextGuest()
      model.nextGuest()
      model.nextGuest (err, username) =>
        this.callback.call this, err, username, 'guest3'
      return
    'check': (err, username, expected) ->
      assert.isNull err
      assert.match username, /^guest[0-9]+/
      assert.equal username, expected

suite.export module
