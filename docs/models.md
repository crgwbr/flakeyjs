## Flakey.models

#### Defining Models
You can define models for your app by extending Flakey.models.Model.

    class Note extends Flakey.models.Model
      @model_name: 'Note', 
      @fields: ['id', 'name', 'content']
      
      # This is a class method
      @foo: () ->
        return "This is a class method"
      
      # These are instance methods
      as_markdown: () ->
        return this.content
      
      as_html: () ->
        # Using the Showdown Markdown -> HTML converter
        converter = new Showdown.converter()
        return converter.makeHtml(this.content);
    
As you can see from the code above, defining a model is very simple. Simply create a new class that extends Flakey.models.Model, set it's model_name parameter to match the name of the class (in this case *Note*), and set the fields parameter to an array fields for this model. This *must* include an id field in addition to you data fields.

#### Creating a new instance
Now that we've defined our model, we can start using it. We can instantiate it a new Note like this:

    # Using the init field shorthand
    grocerys = new Note {
      name: "Grocery List"
    }
    
    # Not using the shorthand
    grocerys = new Note()
    grocerys.name = "Grocery List"
    
    grocerys.save()

This creates a new instance of Note and sets its name field to "Grocery List". Finally we save it. Save a model will generate a diff of each of it's fields, and push the difference onto the `grocerys.versions` array. Then the model is written into each of the activated storage backends.

#### About storage backends
Storage backends are methods of saving models for later use. By default the memory backend (an object located at window.memcache) and the localStorage backend are enabled. Via settings, you can enable the server (ajax storage) and socketio (realtime server storage with push updates).

When an model instance is saved, it is written to each enabled storage backend. If for some reason saving to a backend fails (like a network interruption), a transaction log is generated and stored in localStorage listing in order the transactions which failed. When ever a new transaction is requested, a backend will check it's log for any pending transactions. If some exist, it will push the new transaction onto the end of the array and attempt to perform the first transaction. If it succeeds, it continues until either another failure or the log is empty.

At page load, it's important to sync each of the storage backends. This is done by calling `Flakey.models.backend_controller.sync('Note')` where the string parameter is the name of your model. This should be called once for each of the models in you app, just after you call `Flakey.init(settings)`. Model sync will try to execute any pending log transactions, and then will compare and sync the objects stored in each. This makes it possible to use a volatile backend (like 'memory') for read actions, thereby reducing server traffic.

#### Version History
First lets add some data so that we have a history to play with:

    # Create a new revision on grocerys
    grocerys.content = "# Grocery List
     - Milk
     - Eggs"
    grocerys.save()
    
    # Add another item to the list
    grocerys.content = "# Grocery List
     - Milk
     - Eggs
     - Cheese"
    grocerys.save()

Now that we have a few versions, we can start to use nifty features of Flakey.js:
    
    # Rollback grocerys to before we added 'cheese' to the list 
    # inital save == version 0, so we want version 1
    i = 1
    time = new Date(note.versions[i].time)
    rev = note.evolve(grocerys.versions[i].version_id)
    
    console.log time        # The timestamp of when this version was created
    
    console.log rev.name    # "Grocery List"
    
    console.log rev.content # "# Grocery List
                            #  - Milk
                            #  - Eggs"
                            
That code lets us non-destructively look at a model instance's past, but what if we want to completely destroy the model current state and rollback to the last version? That's even easier:

    # Destroy the latest version
    grocerys.pop_version()
    groceries.write()
    
This snippet pops the latest version from the array and writes it to the enabled storage backends. Note that we call write() here instead of save(). That is because save() is designed to create a *new* version by running a diff on the model fields. Since we don't want to do that here, we call the lower level write() method to directly write the version history to the backends.










