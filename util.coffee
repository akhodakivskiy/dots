connect = require 'connect'

userSetter = (store, sid, session, cb) ->
  store.client.incr 'dots:ids:guest', (err, res) ->
    if err then cb err
    else
      session.username = "guest#{res}"
      store.set sid, session, (err) ->
        if err then cb err
        else
          cb null, session.username

userGetter = (store, socket, cb) ->
  db = store.client

  cookie_string = socket.data.headers.cookie or ""
  parsed_cookie = connect.utils.parseCookie(cookie_string)
  if sid = parsed_cookie['connect.sid']
    store.get sid, (err, session) ->
      if err then cb err
      else
        if !session.username
          userSetter store, sid, session, cb
        else
          cb null, session.username

@userGetter = (store) ->
  (socket, cb) -> userGetter store, socket, cb
