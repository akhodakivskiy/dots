Server      = require './server/server'
BoardsIndex = require './objects/boardsindex'

AccountPlugin = require './plugins/account'
BoardPlugin   = require './plugins/board'
MessagePlugin = require './plugins/message'
MovePlugin    = require './plugins/move'

class DotsServer extends Server
  constructor: (io, opts) ->
    opts.timeout ?= 60000
    super(io, opts)

    index = new BoardsIndex

    @plugins = 
      session : new AccountPlugin this
      board   : new BoardPlugin   this, index
      message : new MessagePlugin this, index
      move    : new MovePlugin    this, index

module.exports = DotsServer
