Store = require '../store'

class MemoryStore extends Store
  constructor: (opts) ->
    super(opts)

    @_nextId = 0
    @_sessions = {}

  get: (sid, cb) ->
    cb null, @_sessions[sid]

  set: (sid, data, cb) ->
    @_sessions[sid] = data
    cb null

  del: (sid, cb) ->
    delete @_sessions[sid]
    cb null

  nextGuest: (cb) ->
    cb null, "guest#{++@_nextId}"

module.exports = MemoryStore
