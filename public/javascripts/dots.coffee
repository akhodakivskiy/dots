class Direction
  @ALL:    new Array()

  @NORTH:  new Direction(0,  -1, "north")
  @NE:     new Direction(1,  -1, "ne")
  @EAST:   new Direction(1,   0, "east")
  @SE:     new Direction(1,   1, "se")
  @SOUTH:  new Direction(0,   1, "south")
  @SW:     new Direction(-1,  1, "sw")
  @WEST:   new Direction(-1,  0, "west")
  @NW:     new Direction(-1, -1, "nw")

  constructor: (@x, @y, @name) ->
    @index = Direction.ALL.length
    Direction.ALL.push this
  
  opposite: ->
    for dir in Direction.ALL
      if dir.x == -this.x and dir.y == -this.y
        return dir
    return null

  next: ->
    index = (@index + 1) % Direction.ALL.length
    return Direction.ALL[index]

  prev: ->
    index = (@index - 1 + Dirction.ALL.length) % Direction.ALL.length
    return Direction.ALL[index]

  ring: ->
    index = _(Direction.ALL).indexOf(this)
    ret = if index == 0 then Direction.ALL \
    else Direction.ALL[index..].concat Direction.ALL[..index-1]

class Dot
  constructor: (@user, @x, @y) ->
    @captive = false

  toString: ->
    return "Dot #{@x} #{@y}"

  neighbor: (dir) ->
    [x, y] = [@x + dir.x, @y + dir.y]
    return @user.board.index?[x]?[y]

  contours: ->
    simplify = (stack) ->
      for dot in stack
        firstIndex = _(stack).indexOf(dot)
        lastIndex = _(stack).lastIndexOf(dot)
        if firstIndex < lastIndex
          one = stack[..firstIndex].concat(stack[lastIndex+1..])
          two = stack[firstIndex..lastIndex-1]
          return [].concat(simplify(one), simplify(two))

      return [stack]

    stop = (stack) ->
      return stack[0] is stack[stack.length - 1]

    walk = (stack, dir) ->
      dot = _.last(stack)
      for i in [0..Direction.ALL.length-1]
        next = dot.neighbor(dir)
        if next and next.user == dot.user and !next.captive
          if _.first(stack) != next
            stack.push(next)
            walk(stack, dir.opposite().next())
          break
        dir = dir.next()
      return stack

    stacks = (simplify(walk([this], dir)) for dir in Direction.ALL when @neighbor(dir)?.user == @user)
    stacks = _(stacks).reduce(((memo, s) -> return memo.concat(s)), [])
    return (new Contour @user, s for s in stacks)

class Contour
  constructor: (@user, @dots) ->

    @captives = new Array
    @count = new Object
    @min = { x: Number.MAX_VALUE, y: Number.MAX_VALUE }
    @max = { x: Number.MIN_VALUE, y: Number.MIN_VALUE }
    for dot in @dots
      @count[dot] += 1
      @min = { x: Math.min(@min.x, dot.x), y: Math.min(@min.y, dot.y) }
      @max = { x: Math.max(@max.x, dot.x), y: Math.max(@max.y, dot.y) }

    $this = this
    @captives = _(@user.board.dots).select \
      (dot) -> return dot.user != @user and $this.contains(dot)

  updateCaptives: ->
    for dot in @captives
      dot.captive = true


  contains: (args...) ->
    board = @user.board

    if args.length < 2
      dot = args[0]
    else
      dot = board.index?[args[0]]?[args[1]]

    if @min.x >= dot.x >= @max.x
      return false
    if @min.y >= dot.y >= @max.y
      return false

    count = { before: 0, after: 0 }
    for x in [@min.x .. @max.x]
      d = board.index?[x]?[dot.y]
      if d and d in @dots
        if x < dot.x
          count.before += @count[d]
        else if x > dot.x
          count.after += @count[d]

    if count.before % 2 == 0 || count.after % 2 == 0
      return false

    count = { before: 0, after: 0 }
    for y in [@min.y .. @max.y]
      d = board.index?[dot.x]?[y]
      if d and d in @dots
        if y < dot.y
          count.before += @count[d]
        else if y > dot.y
          count.after += @count[d]

    if count.before % 2 == 0 || count.after % 2 == 0
      return false
    
    return true
    
class Player
  constructor: (@board, @style) ->
    @contours = new Array()

  add: (x, y) ->
    dot = new Dot(this, x, y)
    @board.dots.push dot
    @board.index[dot.x] ?= new Object
    @board.index[dot.x][dot.y] = dot

    this.addContour dot

  addContour: (dot) ->
    contours = dot.contours()

    reduce = (memo, contour) ->
      memo.push(contour)
      return _(memo)
        .select( ( c ) ->
          if c != contour
            common = _.intersect(c.captives, contour.captives)
            if common.length > 0
              if c.captives.length <= contour.captives.length
                return false
              else if c.dots.length > contour.dots.length
                  return false

          return c.captives.length > 0
        )

    @contours = _(@contours.concat(contours)).reduce(reduce, [])
    for c in @contours
      c.updateCaptives()

class Board
  constructor: (@width, @height) ->

    @user = new Player this, 'blue'
    @enemy = new Player this, 'red'
    @dots = new Array
    @index = new Object

  add: (x, y, user) ->
    for dot in @dots
      if dot.x == x and dot.y == y
        return
    if @width == 0 or @height == 0 or (x >= 0 and x <= @width and y >= 0 and y <= @height)
      if user in [ 'user', @user ] or not user
        user = @user
      else if user in [ 'enemy', @enemy ]
        user = @enemy

      user.add x, y

  clear: ->
    @dots.length = 0
    @index.length = 0
    @user.contours.length = 0
    @enemy.contours.length = 0

@dots =
  Board:  Board
  Player: Player
  Dot:    Dot
