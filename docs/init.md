## Initalizing Flakey.js on page load

Flakey.js requires you do a bit of setup on pageload:

    # Alias Flakey's copy of JQuery
    $ = Flakey.$

    # Get the controller to display first
    controllers = require('./controllers')

    # This function customizes a few settings, syncs 
    # our models, and displays the initial controller
    $(document).ready () ->
      settings = {
        container: $('body')
        base_model_endpoint: '/api'
      }
      Flakey.init(settings)

      # Sync models
      Flakey.models.backend_controller.sync('Note')
      
      note_app = window.note_app = new controllers.MainStack()
      note_app.make_active()
    
The above code comes from the example Note taking application (index.coffee). We'll go over controllers later, for now the most important part to pay attention to are the settings and the call to `Flakey.init`. Here is a list of settings you can customize with `Flakey.init` (with its default value in parenthesis).

- **diff_text**: (true) If true, Flakey will save strings by generating git-like text patches. If false, it will save the entire string in each version. Either way will be transparent to your application, since Flakey takes care of rendering the the patches into a string before loading it into your model. The only time this would make a difference is performance vs. model size.
- **container**: (undefined) *Required*. This is the container to use for your app's controllers. Generally its ok to set it to `$(body)`
- **read_backend**: ('memory') This is the storage backend to use for common read operations, generally 'memory' works well, and is certainly the fastest. Other available backends are 'local' (localStorage), 'server' (JSON api, if its enabled), and 'socketio' (socketio server interface, if its enabled).
- **base_model_endpoint**: (null) Setting this option to your JSON api's base URL enables saving data to the server backend. This is better documented in the Server API docs.
- **socketio_server**: (null) Set this option to your socket.io server's URL to enabled realtime model saving/updating (including server push). You can include a namespace (e.g. http://localhost:8080/models) if so desired.
- **enabled_local_backend**: (true) This option enabled the localStorage backend. Its normally safe to leave this enabled.