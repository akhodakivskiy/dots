Plugin = require '../server/plugin'

class MovePlugin extends Plugin
  constructor: (@server, @index) ->
    super

  connection: (sid) ->
    @register sid, 'move', =>
      @onMove.apply this, arguments

  disconnect: (sid) ->

  onMove: (sid, move, cb) ->
    response = {}
    username = @session(sid)?.username
    if board = @index.board username
      if not board.canMove username
        response.error = "Can't make a move: not your turn"
      else if board.hasDot move.x, move.y
        response.error = "Can't make a move: this position is already occupied"
      else
        dot = board.addMove username, move.x, move.y
        @broadcast board.id, 'move', dot
        response.success = true
    else
      response.error = "Can't make a move: the game hasn't yet started"

    cb? response

module.exports = MovePlugin

