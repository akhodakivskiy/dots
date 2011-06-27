Plugin  = require '../server/plugin'
Board   = require '../objects/board'
Dot     = require '../objects/dot'

sanitize = require('validator').sanitize

class MessagePlugin extends Plugin
  constructor: (@server, @index) ->
    super(@server)

    @index.on 'added', (board) =>
      @message board, null, 'game began' 
    @index.on 'removed', (board) =>
      @message board, null, 'game ended' 

  connection: (sid) ->
    @register sid, 'msg', =>
      @onMessage.apply this, arguments

    if username = @session(sid)?.username
      if board = @index.board username
        @message board, null, "#{username} connected"

  disconnect: (sid) ->
    if username = @session(sid)?.username
      if board = @index.board username
        @message board, null, "#{username} disconnected"

  onMessage: (sid, message, cb) ->
    console.log message
    response = error: "You can't send a message to this board"
    if board = @index.board @session(sid)?.username
      if board.canMessage username
        @message board, username, sanitize(message).xss()
        response.success = true
        delete response.error
    cb response

  message: (board, username, message) ->
    msg = board.addMessage username, message
    @broadcast board.id, 'msg', msg


module.exports = MessagePlugin
