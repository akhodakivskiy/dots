redobj  = require '../../vendor/redobj'
async   = require 'async'

class BoardModel extends redobj.Redobj
  constructor: (@client) ->
    @moveModel    = require('./move')(@client)
    @messageModel = require('./message')(@client)

    keys = 
      date:   redobj.value()
      users:  redobj.set('backref')
      next:   redobj.value()
      moves:  redobj.list()

    super @client, 'board', keys

  create: (username1, username2, cb) ->
    board = 
      users: [username1, username2]
      next: username1
      date: new Date
    @set board, cb
  
  opponent: (bid, username, cb) ->
    @get bid, ['users'], (err, board) =>
      if err 
        cb err
      else if not board 
        cb "board #{bid} does not exist"
      else
        op = null
        if username in board.users
          for u in board.users
            if u != username
              op = u
              break
        cb null, op

  canMove: (bid, username, cb) ->
    @get bid, ['next'], (err, board) ->
      if err
        cb err
      else if not board
        cb "board #{bid} does not exist"
      else
        cb null, board.next == username

  addMove: (bid, x, y, username, cb) ->
    async.waterfall [
      (cb)            => @canMove bid, username, cb
      (can, cb)       => 
        if not can then cb "#{username} can`t make a move now"
        else @opponent bid, username, cb
      (opponent, cb)  => @set { _id: bid, next: opponent}, ['next'], cb
      (board, cb)     => @moveModel.addMove bid, x, y, username, cb
    ], cb

  getMove: (bid, x, y, cb) ->
    @moveModel.getMove bid, x, y, cb

  allMoves: (bid, cb) ->
    @moveModel.allMoves bid, cb

  canMessage: (bid, username, cb) ->
    @get bid, ['users'], (err, board) ->
      if err
        cb err
      else if not board
        cb "board #{bid} does not exist"
      else
        cb null, username in board.users

  addMessage: (bid, message, username, cb) -> 
    if username is null
      @messageModel.addMessage bid, message, username, cb
    else
      @canMessage bid, username, (err, can) =>
        if err then cb err
        else if not can then cb "#{username} can`t message this board"
        else
          @messageModel.addMessage bid, message, username, cb

  allMessages: (bid, cb) ->
    @messageModel.allMessages bid, cb

  del: ->
    @del.call this, arguments

module.exports = (client) -> new BoardModel client
