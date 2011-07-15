Plugin  = require '../server/plugin'
Board   = require '../objects/board'
Dot     = require '../objects/dot'
config  = require '../../config'

class BoardPlugin extends Plugin
  constructor: (@server, @index) ->
    super(@server)
    @endTimers = {}

    @server.emitter.on 'account.join', (sid, username) =>
      if board = @index.board username
        @index.disarmRemove board
        @join sid, board.id
        @emit sid, 'board.begin', board.toObject()

    @server.emitter.on 'account.leave', (sid, username) =>
      if board = @index.board username
        @leave sid, board.id
        @index.armRemove board, config.board.timeout

    @index.on 'added', (board) =>
      for username in board.users
        @join @userSid(username), board.id
      @broadcast board.id, 'board.begin', board.toObject()

    @index.on 'removed', (board) =>
      @broadcast board.id, 'board.end'
      for username in board.users
        @leave @userSid(username), board.id

  connection: (sid) ->
    @register sid, 'board.begin',  =>
      @onBegin.apply this, arguments
    @register sid, 'board.end',    => 
      @onEnd.apply this, arguments

  disconnect: (sid) ->

  onBegin: (sid, data, cb) ->
    response = {}
    if username = @session(sid)?.username
      if @index.board username
        response.error = "Can't begin game: you are already playing on another board"
      else
        @index.queue username
        response.success = true 
    else
       response.error = "Can't begin game: session is invalid, please refresh the page"
    cb response


  onEnd: (sid, data, cb) ->
    response = {}
    if username = @session(sid)?.username
      @index.deque username
      if board = @index.board username
        @index.remove board
        response.success = true 
      else
        response.error = "Can't end game: you don't play on any board"
    else
      response.error = "Can't end game: session is invalid, please refresh the page"
    cb response

  userSid: (username) ->
    for sid, session of @server.sessions
      if session.username is username
        return sid
    null

module.exports = BoardPlugin
