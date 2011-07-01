vows          = require 'vows'
assert        = require 'assert'
EventEmitter  = require('events').EventEmitter

Server        = require '../dots/server/server'

IOMock = ->
  sockets: new EventEmitter

ServerMock = ->
  new Server(new IOMock)

SocketMock = (id) ->
  emitter = new EventEmitter
  emitter.id = id
  return emitter

suite = vows.describe 'server'

suite.addBatch
  'socket connection':
    topic: () ->
      server = new ServerMock
      server.emitter.on 'connection', (sid) =>
        this.callback null, sid

      server.io.sockets.emit 'connection', new SocketMock('sid')
      return

    'connected': (err, sid) ->
      assert.isNull err
      assert.isNotNull sid 

  'socket disconnect':
    topic: () ->
      server = new ServerMock
      server.emitter.on 'disconnect', (sid) =>
        this.callback null, sid

      socket = new SocketMock('sid')
      server.io.sockets.emit 'connection', socket 
      socket.emit 'disconnect'
      return

    'disconnect': (err, sid) ->
      assert.isNull err
      assert.isNotNull sid 



suite.export(module)
