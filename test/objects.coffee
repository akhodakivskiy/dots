vows    = require 'vows'
assert  = require 'assert'

BoardsIndex   = require '../dots/objects/boardsindex'
Board         = require '../dots/objects/board'
Dot           = require '../dots/objects/dot'

suite = vows.describe 'board'

suite.addBatch
  'board functions':
    topic: new Board 'user1', 'user2'

    'id': (board) ->
      assert.isNotNull board.id

    'can move': (board) ->
      assert.isTrue board.canMove 'user1', "user1 should be able to move"
      assert.isFalse board.canMove 'user2', "user2 shouldn't be able to move"

    'illegal move': (board) ->
      board.addMove('user2', 1, 1)
      assert.isFalse board.hasDot 1, 1
      assert.length board.moves, 0

    'legal move': (board) ->
      board.addMove 'user1', 1, 1
      assert.isTrue board.hasDot(1, 1), 'must have a dot after a legal move'
      assert.length board.moves, 1

      dot = board.dot 1, 1
      assert.instanceOf dot, Dot
      assert.equal dot.x, 1
      assert.equal dot.y, 1
      assert.equal dot.username, 'user1'
    
    'can send a message': (board) ->
      assert.isTrue board.canMessage 'user1'
      assert.isFalse board.canMessage 'anon'

    'send a message': (board) ->
      board.addMessage 'user1', 'hello world'
      assert.length board.messages, 1

      assert.equal board.messages[0].username, 'user1'
      assert.equal board.messages[0].message, 'hello world'

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
