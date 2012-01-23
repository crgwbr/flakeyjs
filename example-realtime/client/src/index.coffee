# ==========================================
# Simple Real Time Chat App
# index.coffee
# ==========================================

Flakey = require('./flakey') # This path will change depending on where your copy of flakey.js is.
$ = Flakey.$

# Our Logged in User
current_user = undefined

# Basic Model to hold our messages
class Message extends Flakey.models.Model
  @model_name: 'Message'
  @fields: ['id', 'content', 'author', 'sent', 'class']
  
class User extends Flakey.models.Model
  @model_name: 'User'
  @fields: ['id', 'name']
  

# Controller to choose username (login)
class LoginController extends Flakey.controllers.Controller
  constructor: (@config) ->
    @id = 'login'
    @class_name = 'login view'
    @actions = {
      'submit #login_form': 'submit'
    }
    super(@config)
    
    @tmpl = Flakey.templates.get_template('login', require('./templates/login'))
    
  render: () ->
    @unbind_actions()
    context = {}
    @html @tmpl.render(context)
    @bind_actions()
    
  submit: (event) =>
    event.preventDefault()
    
    choosen_name = $('#choose_username').val().replace(/[^a-zA-Z 0-9]+/g, '')
    
    if not choosen_name.length
      return
    
    $('#choose_username').val("")
    
    users = User.find({name: choosen_name})
    
    if users.length > 0
      alert('That username is already taken.')
      return
      
    current_user = new User {
      name: choosen_name
    }
    current_user.save () =>
      @make_inactive()
      message = new Message {
        author: "System"
        class: "system-broadcast"
        content: "#{current_user.name} has joined the chat. (#{ (new Date).toLocaleString() })"
        sent: +(new Date())
      }
      message.save()
      chat = new ChatController(@config)
      chat.make_active()
        
    # SocketIO for User status
    if current_user?
      @user_socket = io.connect("http://#{ window.location.host }/users")
      
      @user_socket.emit 'associate', current_user.id
      
      @user_socket.on 'delete_user', (user_id) ->
        user = User.get(user_id)
        user.delete()
              
    
    
class ChatController extends Flakey.controllers.Controller
  constructor: (config) ->
    @id = 'chat'
    @class_name = 'chat view'
    @actions = {
      'submit #message_form': 'send'
    }
    super(config)
    
    @tmpl = Flakey.templates.get_template('chat', require('./templates/chat'))
    
    # Listen for updates
    Flakey.events.register 'model_message_updated', () =>
      console.log('rendering (message update)')
      @render()
      
    Flakey.events.register 'model_user_updated', () =>
      console.log('rendering (user update)')
      @render()
    
  render: () ->
    @unbind_actions()
    context = {
      messages: Message.all()
      users: User.all()
    }
    @html @tmpl.render(context)
    @bind_actions()
    $('#new_message').focus()
    
  send: (event) =>
    event.preventDefault()
    
    message = $('#new_message').val()
    if not message.length
      return
    $('#new_message').val("")
    
    message = new Message {
      author: current_user.name
      content: message
      sent: +(new Date())
    }
    message.save()

# Start the App!
$(document).ready () ->
  settings = {
    container: $('body')
    socketio_server: 'http://localhost/models' # Namespace the model sync to protect it from anything else we might do
    enabled_local_backend: false
  }
  Flakey.init(settings)
  
  # Sync models
  Flakey.models.backend_controller.sync('Message')
  Flakey.models.backend_controller.sync('User')
  
  # Debuging
  window.Message = Message
  window.User = User
  
  login = new LoginController()
  login.make_active()
  