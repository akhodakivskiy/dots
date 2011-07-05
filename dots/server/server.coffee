EventEmitter  = require('events').EventEmitter
MemoryStore   = require './stores/memory'
Store         = require './store'
Session       = require './session'

parseCookie = (str) ->
  obj = {}
  pairs = str.split /[;,] */
  for pair in pairs
    eqlIndex = pair.indexOf '='
    key = pair.substr(0, eqlIndex).trim().toLowerCase()
    val = pair.substr(++eqlIndex, pair.length).trim()

    if val[0] == '"'
      val = val.slice 1, -1

    if obj[key] is undefined
      obj[key] = decodeURIComponent(val.replace /\+/g, ' ')
  obj

class Server
  constructor: (@io, @opts) ->
    opts ?= {}
    opts.store ?= new MemoryStore
    @emitter = new EventEmitter
    @_sockets = {}
    @_sessions = {}

    @io.set 'authorization', @_authorize

    @io.sockets.on 'connection', (socket) =>
      @_sessionGetter socket, opts.store, (err, session) =>
        if not err
          @_sockets[session.id] = socket
          @_sessions[session.id] = session
          @emitter.emit 'connection', session.id

          socket.on 'disconnect', =>
            @emitter.emit 'disconnect', session.id
            delete @_sessions[session.id]
            delete @_sockets[session.id]
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
    if socket = @_sockets[sid]
      socket.emit event, data, cb

  socket: (sid) ->
    return @_sockets[sid]

  session: (sid) ->
    return @_sessions[sid]

  _authorize: (data, cb) ->
    newData = {}
    cookies = parseCookie data.headers.cookie
    if id = cookies['dots.sid']
      newData['dots.sid'] = id
    
    cb null, true, newData

  _sessionGetter: (socket, store, cb) ->
    session = new Session socket, store
    session.load (err) ->
      if err is Store.NOT_EXISTS
        session.save (err) ->
          cb err, session
      else
        cb err, session

module.exports = Server

