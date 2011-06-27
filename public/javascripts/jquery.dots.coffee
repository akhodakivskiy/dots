$ = jQuery

class RenderHandler
  constructor: (@canvas, settings) ->
    that = this
    $(document).bind 'dots.board.render', (e, message) ->
      if board = $(canvas).data('board')
        that.render(board, settings)

  render: (board, settings) ->
    s = settings
    @canvas.width  = s.size.width * s.cell.width + 5
    @canvas.height = s.size.height * s.cell.height + 5
    ctx = @canvas.getContext?('2d')
    if ctx
      ctx.save()
      ctx.clearRect(0, 0, @canvas.width, @canvas.height)
      ctx.translate(2.5, 2.5)

      contours = [].concat(board.user.contours).concat(board.enemy.contours)
      @renderGrid(ctx, s.size, s.cell, s.offset)
      @renderDots(ctx, board.dots, s.cell, s.offset)
      @renderContours(ctx, contours, s.cell, s.offset)

      ctx.restore()

  renderGrid: (ctx, size, cell, offset) ->
    dx = offset.x % cell.width
    dy = offset.y % cell.height
    width = size.width * cell.width
    height = size.height * cell.height

    ctx.strokeStyle = 'rgba(0, 0, 0, .2)'
    ctx.beginPath()
    for i in [0 .. size.width]
      x = i * cell.width + dx
      ctx.moveTo(x, 0)
      ctx.lineTo(x, height)

    for i in [0 .. size.height]
      y = i * cell.height + dy
      ctx.moveTo(0,     y)
      ctx.lineTo(width, y)
    ctx.stroke()

  renderDots: (ctx, dots, cell, offset) ->
    for dot in dots
      x = dot.x * cell.width + offset.x
      y = dot.y * cell.height + offset.y
      ctx.fillStyle = if dot.captive then null else dot.user.style
      ctx.strokeStyle = dot.user.style
      ctx.beginPath()
      ctx.arc(x, y, 3, 0, Math.PI * 2, true)
      ctx.closePath()
      if dot.captive
        ctx.stroke()
      else
        ctx.fill()

  renderContours: (ctx, contours, cell, offset) ->
    for contour in contours
      ctx.strokeStyle = contour.user.style
      ctx.fillStyle = contour.user.style
      if contour.dots.length > 2
        ctx.beginPath()
        for dot in contour.dots
          x = dot.x * cell.width + offset.x
          y = dot.y * cell.height + offset.y
          ctx.lineTo x, y
        ctx.closePath()
        ctx.globalAlpha = .1
        ctx.fill()
        ctx.globalAlpha = 1
        ctx.stroke()

class BoardHandler
  constructor: (@board) ->
    $(document).bind 'dots.board.move', (e, move) ->
      username = $(document).data 'username'
      user = if move.username is username then 'user' else 'enemy'
      board.add move.x, move.y, user
      $(document).trigger('dots.board.render')


class MouseHandler
  constructor: (canvas, @settings) ->
    @mouseDown  = false
    @start      = { x: 0, y: 0 }
    @offset     = { x: 0, y: 0 }

    that = this
    $(canvas).bind
      mousedown: ((e) -> that.down(e))
      mousemove: ((e) -> that.move(e))
      mouseup:   ((e) -> that.up(e))

  canvasx: (e) ->
    if e.pageX
      posx = e.pageX
    else if e.clientX
      posx = e.clientX + document.body.scrollLeft + document.documentElement.scrollLeft

    return posx - e.target.offsetLeft

  canvasy: (e) ->
    if e.pageY
      posy = e.pageY
    else if e.clientY
      posy = e.clientY + document.body.scrollTop + document.documentElement.scrollTop

    return posy - e.target.offsetTop

  down: (e) ->
    @mouseDown = true
    @start  = { x: @canvasx(e), y: @canvasy(e) }
    @offset = @settings.offset

  move: (e) ->
    if @mouseDown
      width = @settings.size.width
      height = @settings.size.height
      if width == 0 or height == 0
        @settings.offset =
          x: @offset.x + @canvasx(e) - @start.x
          y: @offset.y + @canvasy(e) - @start.y
        $(document).trigger('dots.board.render')

  up: (e) ->
    pos = { x: @canvasx(e), y: @canvasy(e) }
    if Math.abs(pos.x - @start.x) < 3 and Math.abs(pos.y - @start.y) < 3
      cell = @settings.cell
      offset = @settings.offset
      pos.x = Math.round (-offset.x + pos.x) / cell.width
      pos.y = Math.round (-offset.y + pos.y) / cell.height
      $(document).trigger('dots.socket.move', [pos.x, pos.y])

    @mouseDown = false

    @start = { x: 0, y: 0}

class SocketHandler
  constructor: ->
    socket = io.connect()

    responseHandler = (response) ->
      $(document).trigger 'dots.status.error', [response.error]

    connectionHandler = (label) ->
      -> $(document).trigger 'dots.status.connection', [label]

    socket.on 'connect'   ,   connectionHandler('connected')
    socket.on 'connecting',   connectionHandler('connecting')
    socket.on 'reconnecting', connectionHandler('reconnecting')
    socket.on 'disconnect',   connectionHandler('disconnected')

    $(document).bind
      'dots.socket.begin': (e) ->
        socket.emit 'board.begin', null, responseHandler
      'dots.socket.end': (e) ->
        socket.emit 'board.end', null, responseHandler
      'dots.socket.message': (e, message) ->
        socket.emit 'msg', message, responseHandler
      'dots.socket.move': (e, x, y) ->
        socket.emit 'move', { x: x, y: y }, responseHandler

    socket.on 'connect', ->

    socket.on 'disconnect', ->

    socket.on 'info', (info) =>
      $(document).data 'username', info.username
      @setSession info.session

    socket.on 'board.begin', (obj) ->
      $(document).trigger 'dots.controls.begin', [obj]

    socket.on 'board.end', ->
      $(document).trigger 'dots.controls.end'

    socket.on 'msg', (msg) ->
      $(document).trigger 'dots.chat.message', [msg]

    socket.on 'move', (move) ->
      $(document).trigger 'dots.board.move', [move]
  
  setSession: (session) ->
    $.cookie session.name, session.id


class ChatHandler
  constructor: (div, ul, input) ->
    div.hide()
    $(document).bind
      "dots.chat.message": (e, msg) ->
        message = msg.message
        d = new Date msg.date
        username = $(document).data 'username'
        switch msg.username
          when null, undefined  then [cls, user] = ['server', 'server']
          when username         then [cls, user] = ['user'  , 'you']
          else                       [cls, user] = ['enemy' , msg.username]
        li = $("<li class=\"#{cls}\"></li>")
          .append("<span class=\"preamble\">#{username}@#{d.getHours()}:#{d.getMinutes()} </span>")
          .append("<span>#{message}</span>")
        $(ul).append(li)
        ul.scrollTop = ul.scrollHeight
      "dots.chat.clear": (e, message, user) ->
        $(ul).empty()
      
      'dots.controls.begin': (e, board) ->
        $(document).trigger 'dots.chat.clear'
        for msg in board.messages
          $(document).trigger 'dots.chat.message', [msg]
        for move in board.moves
          $(document).trigger 'dots.board.move', [move]
        div.show() 
      'dots.controls.end': (e) ->
        div.hide() 

    $(input).keypress (e) ->
      if (e.which or e.keyCode) == 13
        message = $(input).val()
        $(document).trigger 'dots.socket.message', [message]
        $(input).val('')

class ControlsHandler
  constructor: (@div) ->
    begin = @createHref('begin').click (e) ->
      $(document).trigger 'dots.socket.begin'
      end.show(); begin.hide()

    end   = @createHref('end').hide().click (e) ->
      $(document).trigger 'dots.socket.end'
      end.hide(); begin.show()

    $(document).bind
      'dots.controls.begin': (e) ->
        begin.hide(); end.show()
      'dots.controls.end': (e) ->
        begin.show(); end.hide()

  createHref: (label) ->
    a = $("<a href=\"#\">#{label}</a>")
    @div.append(a)
    return a

class StatusHandler
  constructor: (@div) ->
    pConnection = $('<p class="connection">disconnected</p>').appendTo @div
    pError = $('<p class=""></p>').hide().appendTo @div

    $(document).bind
      'dots.status.connection': (e, text) ->
        pConnection.text(text)
      'dots.status.error': (e, text) ->
        pError.text text
        pError.stop(true, true).fadeIn('fast').delay(5000).fadeOut('fast')

methods =
  socket: ->
    socket = new SocketHandler
    $(document).data('socket', socket)

  board: (options = {}) ->
    if canvas = document.createElement('canvas')
      $(this).append(canvas)

      settings =
        size:   { width: 32, height: 24 }
        cell:   { width: 20, height: 20 }
        offset: { x: 0, y: 0 }
      $.extend(settings, options)

      board = new dots.Board settings.size.width, settings.size.height

      handlers =
        'mouse'     : new MouseHandler canvas, settings
        'renderer'  : new RenderHandler canvas, settings
        'board'     : new BoardHandler board

      $(canvas).data('board', board)
      $(canvas).data('handlers', handlers)

      $(document).trigger('dots.board.render')

  controls: ->
    new ControlsHandler $(this)
  
  status: ->
    new StatusHandler $(this)

  chat: (type) ->
    $this = $(this)
    ul = $('<ul/>')
    input = $('<input type="text" placeholder="Type Your Messsage"/>')
    $this.append(ul).append(input)

    chat = new ChatHandler $this, ul, input
    $this.data('chat', chat)

$.fn.dots = (method) ->
  args = arguments
  @each ->
    m = method or 'init'
    if m of methods
      return methods[m].apply(this, Array.prototype.slice.call(args, 1))
    else $.error( "Method #{m} does not exist on jQuery.dots" )

