class Plugin
  constructor: (@server) ->
    @server.emitter.on 'connection', (sid) =>
      @connection sid

    @server.emitter.on 'disconnect', (sid) =>
      @disconnect sid

    funcs = [
      'register',
      'join',
      'leave',
      'broadcast',
      'emit',
      'socket',
      'session'
    ] 
    
    for name in funcs
      @_wrap name

  _wrap: (name) ->
    @[name] = ->
      @server[name].apply @server, arguments

Plugin::connection = null

Plugin::disconnect = null

module.exports = Plugin
