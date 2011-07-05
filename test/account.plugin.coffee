vows    = require 'vows'
assert  = require 'assert'
redis   = require 'redis'
config  = require '../config'

Server        = require '../dots/server/server'
AccountPlugin = require '../dots/plugins/account'
mocks         = require './mocks/io'

suite = vows.describe 'account plugin'

client = redis.createClient(config.redis?.host, config.redis?.port)
client.auth config.redis.auth
client.select 14
client.flushdb()

suite.addBatch
  'guest login':
    topic: () ->
      server = new Server(new mocks.IOMock)
      plugin = new AccountPlugin server, client

      server.emitter.on 'account.join', (sid, username) =>
        this.callback null, server, sid, username
      server.io._connect 'socket id', 'session id'
      return

    'after': (err, server, sid, username) ->
      assert.match username, /guest[0-9]+/
      assert.equal sid, 'session id'

  'user authentication':
    topic: () ->
      server = new Server(new mocks.IOMock)
      plugin = new AccountPlugin server, client

      server.emitter.on 'account.join', (sid, username) =>
        if username is 'username'
          this.callback null, server, sid, username

      server.io._connect 'socket id', 'session id'

      server.socket('session id').emit( 
        'account.authenticate'
        { username: 'username', password: 'password' }
      )
      return

    'after': (err, server, sid, username) ->
      assert.equal username, 'username'

    'logout':
      topic: (server, sid, username) ->
        server.emitter.on 'account.leave', (sid, username) =>
          this.callback null, server, sid, username

        server.socket('session id').emit 'account.logout'

      'after': (err, server, sid, username) ->
        assert.equal username, 'username'


suite.export module
