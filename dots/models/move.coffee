redobj  = require '../../vendor/redobj'

class MoveModel extends redobj.Redobj
  constructor: (@client) ->
    keys =
      x       : redobj.value('backref')
      y       : redobj.value('backref')
      username: redobj.value('backref')
      boardId : redobj.value('backref')
      date    : redobj.value()

    super @client, 'move', keys

  addMove: (bid, x, y, username, cb) ->
    @getMove bid, x, y, (err, move) =>
      if err then cb err
      else if move then cb 'this position is already occupied'
      else @set { x: x, y: y, username: username, boardId: bid }, cb

  getMove: (bid, x, y, cb) ->
    @find x: x, y: y, cb

  allMoves: (bid, cb) ->
    @mfind boardId: bid, cb

module.exports = (client) -> new MoveModel client
