vows        = require 'vows'
assert      = require 'assert'
events      = require 'events'
Board       = require '../../dots/board'
Dot         = require '../../dots/dot'
DotsServer  = require '../../dots'

EventEmitter = events.EventEmitter

suite = vows.describe 'dots game'

suite.addBatch
  'game':
    topic: new DotsServer

    'start': (game) ->
      game.begin 'user1', null
      assert.isNull game.begin 'user', 'user'
      assert.isNull game.begin
      board = game.begin 'user1', 'user2'


suite.export module
