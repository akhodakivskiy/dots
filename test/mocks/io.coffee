EventEmitter  = require('events').EventEmitter

class IOMock
  constructor: ->
    @sockets = new EventEmitter
  set: ->
  _connect: (id, sid) ->
    socket = new SocketMock id, sid
    @sockets.emit 'connection', socket

class SocketMock extends EventEmitter
  constructor: (@id, sid) ->
    @handshake = { 'dots.sid': sid }
  _disconnect: -> @emit 'disconnect'

module.exports = 
  IOMock     : IOMock
  SocketMock : SocketMock
