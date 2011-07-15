vows    = require 'vows'
assert  = require 'assert'
redis   = require 'redis'
config  = require '../config'

client = redis.createClient(config.redis?.host, config.redis?.port)
client.auth config.redis.auth
client.select 15
client.flushdb()

model = require('../dots/models/board')(client)

suite = vows.describe 'user model'
suite.addBatch
  'create board':
    topic: ->
      model.create 'username1', 'username2', this.callback
    'created': (err, board) ->
      assert.isNull err
      assert.include board.users, 'username1'
      assert.include board.users, 'username2'
      assert.equal board.next, 'username1'
      assert.isNotNull board.id

suite.addBatch
  'opponent':
    topic: ->
      model.opponent 1, 'username1', this.callback
    'opponent returned': (err, username) ->
      assert.equal username, 'username2'

  'can move/message':
    topic: ->
      model.canMove     1, 'username1', this.callback
      model.canMessage  1, 'username1', this.callback
      model.canMessage  1, 'username2', this.callback
    'yes we can': (err, username) ->
      assert.isNull err
      assert.isTrue username 

  'can`t move/message':
    topic: ->
      model.canMove     1, 'username2', this.callback
      model.canMessage  1, 'username3', this.callback
    'no we can`t': (err, username) ->
      assert.isNull err
      assert.isFalse username 

suite.addBatch
  'add messages':
    topic: ->
      model.addMessage 1, 'message1', 'username1', this.callback
      model.addMessage 1, 'message2', 'username2', this.callback
    'message added': (err, msg) ->
      assert.isNull err
      assert.match msg.message, /message\d/
      assert.match msg.username, /username\d/
      assert.equal msg.boardId, 1
  'add message from someone else':
    topic: ->
      model.addMessage 1, 'message', 'username3', this.callback
    'message was not added': (err, msg) ->
      assert.isNotNull err
      assert.isUndefined msg
  'add system message':
    topic: ->
      model.addMessage 1, 'system message', null, this.callback
    'system message added': (err, msg) ->
      assert.isNull err
      assert.equal msg.message, 'system message'
      assert.isNull msg.username
      assert.equal msg.boardId, 1

suite.addBatch
  'get all messages':
    topic: ->
      model.allMessages 1, this.callback
    'should contain 3 messages': (err, msgs) ->
      assert.length msgs, 3

suite.addBatch
  'add move':
    topic: ->
      model.addMove 1, 0, 0, 'username1', this.callback
    'move added': (err, move) ->
      assert.isNull err
      assert.match move.username, /username\d/
      assert.equal move.boardId, 1
      assert.equal 0, move.x
      assert.equal 0, move.y
    'next move':
      topic: (move, board) ->
        model.addMove 1, 1, 1, 'username2', this.callback
      'move added': (err, move) ->
        assert.isNull err
        assert.match move.username, /username\d/
        assert.equal move.boardId, 1
        assert.equal 1, move.x
        assert.equal 1, move.y

suite.addBatch
  'repeat move':
    topic: ->
      model.addMove 1, 0, 0, 'username1', this.callback
    'move not added': (err, move) ->
      assert.equal err, 'this position is already occupied'
      assert.isUndefined move
  'try to make a move':
    topic: ->
      model.addMove 1, 2, 2, 'username2', this.callback
    'move not added': (err, move) ->
      assert.equal err, 'username2 can`t make a move now'
      assert.isUndefined move

suite.addBatch
  'get all moves':
    topic: ->
      model.allMoves 1, this.callback
    'return 2 moves': (err, moves) ->
      assert.isNull err
      assert.length moves, 2
      assert.equal moves[0].x, 0
      assert.equal moves[0].y, 0
      assert.equal moves[0].boardId, 1
      assert.equal moves[0].username, 'username1'
      assert.equal moves[1].x, 1
      assert.equal moves[1].y, 1
      assert.equal moves[1].boardId, 1
      assert.equal moves[1].username, 'username2'
  'get move at 0, 0':
    topic: ->
      model.getMove 1, 0, 0, this.callback
    'return valid move': (err, move) ->
      assert.isNull err
      assert.equal move.username, 'username1'

  'get move at 0, 1':
    topic: ->
      model.getMove 1, 0, 1, this.callback
    'move does not exist': (err, move) ->
      assert.isNull err
      assert.isNull move

suite.addBatch
  'remove board':
    topic: ->
      model.del 1, this.callback
    'destroyed': (err, board) ->
      assert.isNull err

suite.export module
