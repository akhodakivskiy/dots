connect     = require 'connect'
jade        = require 'jade'
redis       = require 'redis'

DotsServer  = require './dots'
RedisStore  = require './dots/server/stores/redis'

routes = connect.router (app) ->
  app.get '/', (req, res) ->
    jade.renderFile './views/index.jade', (err, html) ->
      if err then throw err
      res.end html

app = connect.createServer(
  connect.static __dirname  + '/public'
  routes
)

app.listen(3000)
io = require('../socket.io').listen(app)
#io = require('socket.io').listen(app)

server  = new DotsServer io, 
  store   : new RedisStore redis.createClient()
  timeout : 5000
