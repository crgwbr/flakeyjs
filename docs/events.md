## Flakey.events

Flakey.js includes a basic event signaling system to allow subscribing to and generating events by means of an Observer-pattern singleton located at Flakey.events. Flakey.js triggers built-in signals for several common events (model updating, etc), but you can also create and trigger your own signals.

#### Creating a new event
In CoffeeScript:

    Flakey.events.register 'map_view_updated', (event, namespace, data) ->
      console.log 'The Map View has been updated!'
      console.log data  # Optional arbitrary data passed in by the trigger
      
In JavaScript:

    Flakey.events.register('map_view_updated', function() {
      console.log('The Map View has been updated!');
      console.log(data); // Optional arbitrary data passed in by the trigger
    })
    
This will register (subscribe) the given function to the signal called `"map_view_updated"`.  Whenever that signal is triggered, our function will be called along with any other functions registered to this event. In addition to the signal name, you can optionally supply a namespace for your signal. For example, you may want to namespace all signals specific to your app under the name "my_app". You can do that with:

In CoffeeScript:
    
    our_fn = (event, namespace, data) ->
      console.log 'The Map View has been updated!'
      console.log data  # Optional arbitrary data passed in by the trigger
      
    Flakey.events.register 'map_view_updated', our_fn, 'my_app'
      
In JavaScript:

    our_fn = function() {
      console.log('The Map View has been updated!');
      console.log(data); // Optional arbitrary data passed in by the trigger
    }
    Flakey.events.register('map_view_updated', our_fn, 'my_app')
    
#### Triggering an event
Triggering an event is even simpler than registering an action.

    Flakey.events.trigger('map_view_updated')

To trigger an event within a namespace:

    Flakey.events.trigger('map_view_updated', 'my_app')
    
Additionally, you may optionally pass in data to be passed to the listening functions like so:

    Flakey.events.trigger('map_view_updated', 'my_app', {id: 42})
    
#### Destroying a namespace
If you wish, its possible to completely wipe the slate clean for a namespace, removing all listening functions.  You can do that by calling:

    Flakey.events.clear('my_app')
    
It's doubtful you'l ever need to do this, but the ability exists if you ever do.

#### Flakey built in events
These common events are built into the default ("flakey") namespace.

- `model_foo_updated` - foo is replaced by the model's name in lowercase (e.g. `model_note_updated`). Called when an instance of the model is saved, passes the instance through in data.

