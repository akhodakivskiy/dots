EventEmitter  = require('events').EventEmitter
MemoryStore   = require './stores/memory'
Store         = require './store'
Session       = require './session'

class Server
  constructor: (@io, @opts) ->
    opts.store ?= new MemoryStore
    @emitter = new EventEmitter
    @sockets = {}
    @sessions = {}

    @io.sockets.on 'connection', (socket) =>
      @_sessionGetter socket, opts.store, (err, session) =>
        if not err
          @sockets[session.id] = socket
          @sessions[session.id] = session
          @emitter.emit 'connection', session.id

          socket.on 'disconnect', =>
            @emitter.emit 'disconnect', session.id
            delete @sockets[session.id]
        else
          console.log "Could not start a session for socket", err.stack
    
  register: (sid, event, cb) ->
    if socket = @socket sid
      socket.on event, (data, _cb) ->
        cb sid, data, _cb

  join: (sid, room) ->
    if socket = @socket sid
      socket.join room

  leave: (sid, room) ->
    if socket = @socket sid
      socket.leave room

  broadcast: (room, event, data) ->
    @io.sockets.in(room).emit event, data

  emit: (sid, event, data, cb) ->
    if socket = @sockets[sid]
      socket.emit event, data, cb

  socket: (sid) ->
    return @sockets[sid]

  session: (sid) ->
    return @sessions[sid]

  _sessionGetter: (socket, store, cb) ->
    session = new Session socket, store
    session.load (err) ->
      if err is Store.NOT_EXISTS
        session.save (err) ->
          cb err, session
      else
        cb err, session

module.exports = Server

