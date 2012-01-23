# ===============================================================
# Copyright 2012 Craig Weber.
#
# This is an example realtime chat app built to demonstrate
# the realtime model-sync capabilities for Flakey.js
# ===============================================================

app = require('express').createServer()
io = require('socket.io').listen(app)

app.listen(8080)

# Static Files to serve for our app
app.get '/', (req, res) ->
  res.sendfile __dirname + '/client/public/index.html'
  
app.get '/style.css', (req, res) ->
  res.sendfile __dirname + '/client/public/style.css' 
  
app.get '/app.js', (req, res) ->
  res.sendfile __dirname + '/client/public/app.js' 

# This will be our "database", where we store all our 
# objects. Chat doesn't need to be persistent, so we just
# use a simple hashtable
chat_cache = {}

# Associates a socket to a user id
users = {}

# User status
users = io.of('/users').on 'connection', (socket) ->
  socket.on 'associate', (user_id) ->
    users[socket.id] = user_id
    
  socket.on 'disconnect', () ->
    socket.broadcast.emit 'delete_user', users[socket.id]


# Listen for Socket.IO client connections on the /models namespace
model_sync = io.of('/models').on 'connection', (socket) ->
  console.log 'Client Connected'
  
  # This event is emited by Flakey by the backend sync'er
  # Need to return a flat list of all objects, e.g. {id: 'foo-bar-asdf', name: 'ModelName', versions:[...]}
  socket.on 'fetch_all', (data) ->
    set = []
    for own name of chat_cache
      (set.push chat_cache[name][id] for own id of chat_cache[name])
    socket.emit 'sync', set
  
  # This event is emited by Flakey to write an object to our
  # store. Notice that after we update the store, we broadcast
  # the change to all other clients using the 'sync' event
  socket.on 'write', (data, callback) ->
    console.log data
    chat_cache[data.name] = chat_cache[data.name] || {}
    chat_cache[data.name][data.id] = data
    # Notify the sender that we saved successfully
    callback()
    # Broadcast the change to all other clients
    socket.broadcast.emit 'sync', [data]
  
  # This event is emited by Flakey to delete an object from
  # our store.
  socket.on 'delete', (data) ->
    if chat_cache[data.name]?
      if chat_cache[data.name][data.id]?
        delete chat_cache[data.name][data.id]
  
  # Standard disconnect event. Remove the socket from our
  # broacast list.
  socket.on 'disconnect', () ->
    console.log 'Client Disconected'
      
      
