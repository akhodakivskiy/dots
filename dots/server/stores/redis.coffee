Store = require '../store'

class RedisStore extends Store
  constructor: (@client, opts) ->
    super(opts)

  _key: (sid) -> "session:#{sid}"

  get: (sid, cb) ->
    @client.get @_key(sid), (err, value) ->
      if err 
        cb err
      else if not value
        cb Store.NOT_EXISTS 
      else
        try
          cb null, JSON.parse value?.toString() or ''
        catch err
          cb err

  set: (sid, data, cb) ->
    try
      @client.set @_key(sid), JSON.stringify(data), (err) =>
        if err then cb err
        else
          if data.age
            @client.expire sid, data.age
          cb null
    catch err
      cb err

  del: (sid, cb) ->
    @client.del @_key(sid), cb

  nextGuest: (cb) ->
    @client.incr "ids:session:guest", (err, val) ->
      cb err, "guest#{val}"

module.exports = RedisStore
