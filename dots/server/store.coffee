
class Store
  constructor: (opts) ->
    @maxAge = opts?.maxAge or 60*60*1000 # 1hr
    @secret = opts?.secret or ''

Store::get = null

Store::set = null

Store::del = null

Store::nextGuest = null

Store.NOT_EXISTS = 'session does not exist'

module.exports = Store
