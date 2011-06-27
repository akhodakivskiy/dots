Dot     = require './dot'
crypto  = require 'crypto'

generateId = ->
  rand = String(Math.random() * Math.random() * Date.now())
  return crypto.createHash('md5').update(rand).digest('hex')


class Board
  constructor: (username1, username2) ->
    @id = generateId()
    @users = [username1, username2]
    @next = username1

    @moves = []
    @movesIndex = []
    @messages = []

  #returns opponent of the user passed in
  opponent: (username) ->
    if username in @users
      for u in @users
        if u is not username
          return u
    null

  #attempt to make a move. return true on success
  addMove: (username, x, y) ->
    dot = null
    if @canMove(username) and not @hasDot(x, y)
      idx = @users.indexOf username
      @next = @users[(idx + 1) % @users.length]

      dot = new Dot username, x, y
      @moves.push dot
      @movesIndex[x] ?= new Array
      @movesIndex[x][y] = dot

    dot

  #check is the username can make a move now
  canMove: (username) ->
    if username != @next or username not in @users
      return false
    true
    
  #returns a dot at the specific position
  dot: (x, y) ->
    @movesIndex?[x]?[y]

  #checks if there is a dot at the specific position
  hasDot: (x, y) ->
    @dot(x, y) instanceof Dot

  #checks if the username can send a message
  canMessage: (username) ->
    not username or username in @users

  addMessage: (username, message) ->
    msg = false
    if @canMessage username
      msg = username: username, date: new Date, message: message
      @messages.push msg

    msg

  toObject: ->
    id        : @id
    next      : @next
    users     : @users
    moves     : @moves
    messages  : @messages

module.exports = Board
