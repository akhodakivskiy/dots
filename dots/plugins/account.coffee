check = require('validator').check
async = require 'async'

Plugin    = require '../server/plugin'

class AccountPlugin extends Plugin
  constructor: (@server, client) ->
    super

    @model = require('../models/user')(client)

  connection: (sid) ->
    @_joinAccount sid, null #restore session

    @register sid, 'account.authenticate',    => 
      @onAuthenticate.apply this, arguments
    @register sid, 'account.logout',  =>
      @onLogout.apply this, arguments

  disconnect: (sid) ->
    @_leaveAccount(sid, false)

  onAuthenticate: (sid, data, cb) ->
    async.waterfall [
      (cb) => @_leaveAccount(sid, true, cb)
      (cb) => @model.authenticate data.username, data.password, cb
      (user, cb) => @_joinAccount sid, user?.username, cb
    ], (err) ->
      cb? { error: err, success: not err }

  onLogout: (sid, data, cb) ->
    async.waterfall [
      (cb) => @_leaveAccount(sid, true, cb)
      (cb) => @_joinAccount sid, null, cb
    ], (err) ->
      cb? { error: err, success: not err }

  _leaveAccount: (sid, clear, cb) ->
    session = @session sid
    if session.username
      @server.emitter.emit 'account.leave', sid, session.username
      if clear
        session.clear cb
      else
        cb null
    else
      cb null

  _joinAccount: (sid, username, cb) ->
    session = @session sid
    async.waterfall [
      (cb) =>
        if username and session.username != username
          session.username = username
          session.guest = false
          session.save()
        cb null, session
      (session, cb) => #guest session
        if session.username
          cb null, session
        else
          @model.nextGuest (err, username) ->
            session.username = username
            session.guest = true
            session.save()
            cb null, session
      (session, cb) =>
        @emit sid, 'info', 
          username: session.username, 
          session:
            name  : 'dots.sid'
            id    : session.id
            guest : session.guest
        @server.emitter.emit 'account.join', sid, session.username
        cb null
    ], (err) ->
      cb? err, username

module.exports = AccountPlugin

