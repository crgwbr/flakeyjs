(function() {
  var app, chat_cache, io, model_sync, users,
    __hasProp = Object.prototype.hasOwnProperty;

  app = require('express').createServer();

  io = require('socket.io').listen(app);

  app.listen(8080);

  app.get('/', function(req, res) {
    return res.sendfile(__dirname + '/client/public/index.html');
  });

  app.get('/style.css', function(req, res) {
    return res.sendfile(__dirname + '/client/public/style.css');
  });

  app.get('/app.js', function(req, res) {
    return res.sendfile(__dirname + '/client/public/app.js');
  });

  chat_cache = {};

  users = {};

  users = io.of('/users').on('connection', function(socket) {
    socket.on('associate', function(user_id) {
      return users[socket.id] = user_id;
    });
    return socket.on('disconnect', function() {
      return socket.broadcast.emit('delete_user', users[socket.id]);
    });
  });

  model_sync = io.of('/models').on('connection', function(socket) {
    console.log('Client Connected');
    socket.on('fetch_all', function(data) {
      var id, name, set, _ref;
      set = [];
      for (name in chat_cache) {
        if (!__hasProp.call(chat_cache, name)) continue;
        _ref = chat_cache[name];
        for (id in _ref) {
          if (!__hasProp.call(_ref, id)) continue;
          set.push(chat_cache[name][id]);
        }
      }
      return socket.emit('sync', set);
    });
    socket.on('write', function(data, callback) {
      console.log(data);
      chat_cache[data.name] = chat_cache[data.name] || {};
      chat_cache[data.name][data.id] = data;
      callback();
      return socket.broadcast.emit('sync', [data]);
    });
    socket.on('delete', function(data) {
      if (chat_cache[data.name] != null) {
        if (chat_cache[data.name][data.id] != null) {
          return delete chat_cache[data.name][data.id];
        }
      }
    });
    return socket.on('disconnect', function() {
      return console.log('Client Disconected');
    });
  });

}).call(this);
