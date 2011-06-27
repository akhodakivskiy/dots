EventEmitter  = require('events').EventEmitter
Board = require './board'

class BoardsIndex extends EventEmitter
  constructor: ->
    @boards = []
    @_queue = []

  queue: (username) ->
    if username not in @_queue
      @_queue.push username
      if @_queue.length > 1
        board = new Board @_queue.shift(), @_queue.shift()
        @boards.push board
        @emit 'added', board

  deque: (username) ->
    if @isQueued username
      @_queue.splice @_queue.indexOf username, 1

  isQueued: (username) ->
    return username in @_queue

  board: (username) ->
    ret = null
    for id, board of @boards
      if username in board.users
        ret = board
    ret

  remove: (board) ->
    idx = @boards.indexOf(board)
    if idx > -1
      @boards.splice(idx, 1)
      @emit 'removed', board

module.exports = BoardsIndex
