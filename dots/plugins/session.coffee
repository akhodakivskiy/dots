Plugin = require '../server/plugin'

class SessionPlugin extends Plugin
  constructor: (@server) ->
    super

  _userGetter: (session, cb) ->
    if username = session.username
      cb null, username
    else
      session._store.nextGuest (err, username) ->
        session.username = username
        session.save (err) ->
          if err then console.log err
        cb err, username

  connection: (sid) ->
    if session = @session sid
      @_userGetter session, (err, username) =>
        if username
          @emit sid, 'info', 
            username: username, 
            session:
              name: 'dots.sid'
              id:   sid
          @server.emitter.emit 'session.join', sid, username

  disconnect: (sid) ->
    if username = @session(sid)?.username
      @server.emitter.emit 'session.leave', sid, username


module.exports = SessionPlugin

