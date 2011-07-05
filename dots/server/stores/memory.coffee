Store = require '../store'

class MemoryStore extends Store
  constructor: (opts) ->
    super(opts)

    @_sessions = {}

  get: (sid, cb) ->
    cb null, @_sessions[sid]

  set: (sid, data, cb) ->
    @_sessions[sid] = data
    cb null

  del: (sid, cb) ->
    delete @_sessions[sid]
    cb null

module.exports = MemoryStore
