vows    = require 'vows'
assert  = require 'assert'
mocks   = require './mocks/io'

Server  = require '../dots/server/server'

suite = vows.describe 'server'

suite.addBatch
  'socket connection':
    topic: ->
      server = new Server(new mocks.IOMock)
      server.emitter.on 'connection', (sid) =>
        this.callback null, server, sid

      server.io._connect 'socket id', 'session id'
      return

    'connected': (err, server, sid) ->
      assert.isNull err
      assert.equal sid, 'session id'
      assert.length Object.keys(server._sessions), 1
      assert.length Object.keys(server._sockets), 1

  'socket disconnect':
    topic: ->
      server = new Server(new mocks.IOMock)
      server.emitter.on 'disconnect', (sid) =>
        this.callback null, server, sid

      server.io._connect 'socket id', 'session id'
      server.socket('session id').emit 'disconnect'
      return

    'disconnect': (err, server, sid) ->
      assert.isNull err
      assert.equal sid, 'session id'
      assert.length Object.keys(server._sessions), 0
      assert.length Object.keys(server._sockets), 0



suite.export(module)
