(function() {
  var $, ChatController, Flakey, LoginController, Message, User, current_user,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Flakey = require('./flakey');

  $ = Flakey.$;

  current_user = void 0;

  Message = (function(_super) {

    __extends(Message, _super);

    function Message() {
      Message.__super__.constructor.apply(this, arguments);
    }

    Message.model_name = 'Message';

    Message.fields = ['id', 'content', 'author', 'sent', 'class'];

    return Message;

  })(Flakey.models.Model);

  User = (function(_super) {

    __extends(User, _super);

    function User() {
      User.__super__.constructor.apply(this, arguments);
    }

    User.model_name = 'User';

    User.fields = ['id', 'name'];

    return User;

  })(Flakey.models.Model);

  LoginController = (function(_super) {

    __extends(LoginController, _super);

    function LoginController(config) {
      this.config = config;
      this.submit = __bind(this.submit, this);
      this.id = 'login';
      this.class_name = 'login view';
      this.actions = {
        'submit #login_form': 'submit'
      };
      LoginController.__super__.constructor.call(this, this.config);
      this.tmpl = Flakey.templates.get_template('login', require('./templates/login'));
    }

    LoginController.prototype.render = function() {
      var context;
      this.unbind_actions();
      context = {};
      this.html(this.tmpl.render(context));
      return this.bind_actions();
    };

    LoginController.prototype.submit = function(event) {
      var choosen_name, users,
        _this = this;
      event.preventDefault();
      choosen_name = $('#choose_username').val().replace(/[^a-zA-Z 0-9]+/g, '');
      if (!choosen_name.length) return;
      $('#choose_username').val("");
      users = User.find({
        name: choosen_name
      });
      if (users.length > 0) {
        alert('That username is already taken.');
        return;
      }
      current_user = new User({
        name: choosen_name
      });
      current_user.save(function() {
        var chat, message;
        _this.make_inactive();
        message = new Message({
          author: "System",
          "class": "system-broadcast",
          content: "" + current_user.name + " has joined the chat. (" + ((new Date).toLocaleString()) + ")",
          sent: +(new Date())
        });
        message.save();
        chat = new ChatController(_this.config);
        return chat.make_active();
      });
      if (current_user != null) {
        this.user_socket = io.connect("http://" + window.location.host + "/users");
        this.user_socket.emit('associate', current_user.id);
        return this.user_socket.on('delete_user', function(user_id) {
          var user;
          user = User.get(user_id);
          return user["delete"]();
        });
      }
    };

    return LoginController;

  })(Flakey.controllers.Controller);

  ChatController = (function(_super) {

    __extends(ChatController, _super);

    function ChatController(config) {
      this.send = __bind(this.send, this);
      var _this = this;
      this.id = 'chat';
      this.class_name = 'chat view';
      this.actions = {
        'submit #message_form': 'send'
      };
      ChatController.__super__.constructor.call(this, config);
      this.tmpl = Flakey.templates.get_template('chat', require('./templates/chat'));
      Flakey.events.register('model_message_updated', function() {
        console.log('rendering (message update)');
        return _this.render();
      });
      Flakey.events.register('model_user_updated', function() {
        console.log('rendering (user update)');
        return _this.render();
      });
    }

    ChatController.prototype.render = function() {
      var context;
      this.unbind_actions();
      context = {
        messages: Message.all(),
        users: User.all()
      };
      this.html(this.tmpl.render(context));
      this.bind_actions();
      return $('#new_message').focus();
    };

    ChatController.prototype.send = function(event) {
      var message;
      event.preventDefault();
      message = $('#new_message').val();
      if (!message.length) return;
      $('#new_message').val("");
      message = new Message({
        author: current_user.name,
        content: message,
        sent: +(new Date())
      });
      return message.save();
    };

    return ChatController;

  })(Flakey.controllers.Controller);

  $(document).ready(function() {
    var login, settings;
    settings = {
      container: $('body'),
      socketio_server: 'http://localhost/models',
      enabled_local_backend: false
    };
    Flakey.init(settings);
    Flakey.models.backend_controller.sync('Message');
    Flakey.models.backend_controller.sync('User');
    window.Message = Message;
    window.User = User;
    login = new LoginController();
    return login.make_active();
  });

}).call(this);
