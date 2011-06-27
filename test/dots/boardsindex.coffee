vows        = require 'vows'
assert      = require 'assert'
events      = require 'events'
Board       = require '../../dots/board'
Dot         = require '../../dots/dot'
BoardsIndex = require '../../dots/boardsindex'

EventEmitter = events.EventEmitter

suite = vows.describe 'board'

suite.addBatch
  'queue user':
    topic: new BoardsIndex
    'queue': (index) ->
      index.on 'added', (board) ->
        assert.include board.users, 'user1'
        assert.include board.users, 'user2'

      index.queue 'user1'
      index.queue 'user2'

      assert.length index.boards, 1
  'remove board':
    topic: new BoardsIndex
    'remove': (index) ->
      index.queue 'user1'
      index.queue 'user2'

      board = index.board 'user1'

      assert.isNotNull board
      assert.include board.users, 'user1'
      assert.include board.users, 'user2'

      index.remove board

      assert.length index.boards, 0


suite.export(module)
           
