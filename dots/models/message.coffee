redobj  = require '../../vendor/redobj'

class MessageModel extends redobj.Redobj
  constructor: (@client) ->
    keys =
      message : redobj.value()
      boardId : redobj.value('backref')
      username: redobj.value('backref')
      date    : redobj.value('date')

    super @client, 'message', keys

  addMessage: (bid, message, username, cb) ->
    msg = 
      message : message
      boardId : bid
      username: username
      date    : new Date()

    @set msg, cb

  allMessages: (bid, cb) ->
    @mfind boardId: bid, cb

module.exports = (client) -> new MessageModel client
