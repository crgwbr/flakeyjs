# ## Model and model backend code

# ### Subclass this to create you own models
class Model
  @model_name: null
  @fields: ['id']
  
  # If your model has a constructor, it should call this via super()
  constructor: (init_values) ->
    @id = Flakey.util.guid()
    @versions = []
    
    for own key, value of init_values
      @[key] = value
  
  # #### Class Methods
  # List all objects
  @all: () ->
    set = []
    for obj in Flakey.models.backend_controller.all(@model_name)
      m = new @()
      m.import(obj)
      set.push(m)
    return set
    
  # Query for a set of objects by a query object. e.g. Model.find({name: 'sam'})
  @find: (query) ->
    ar = Flakey.models.backend_controller.find(@model_name, query)
    if not ar.length
      return []

    set = []
    for item in ar
      m = new @()
      m.import(item)
      set.push(m)
    return set

  # Query for a single object by it's id
  @get: (id) ->
    obj = Flakey.models.backend_controller.get(@model_name, id)
    if not obj
      return undefined
    m = new @()
    m.import(obj)
    return m
  
  # Full Text Search fields based on the given string / regular expression
  @search: (re, fields = @fields) ->
    query = {}
    for key in fields
      query[key] = re
    ar = Flakey.models.backend_controller.search(@model_name, query)
    if not ar.length
      return []

    set = []
    for item in ar
      m = new @()
      m.import(item)
      set.push(m)
    return set
  
  # #### Public Methods
  # Delete this instance from all backends. Just like a real database, this is irreversible.
  delete: () ->
    Flakey.models.backend_controller.delete(@constructor.model_name, @id)
    event_key = "model_#{ @constructor.model_name.toLowerCase() }_updated"
    Flakey.events.trigger(event_key, undefined)
  
  # Rollback this instance. If version_id is numeric, rollback that many versions. If it's a version_id, rollback to that version.
  rollback: (version_id) ->
    if parseInt(version_id) < @versions.length
      for i in Array(parseInt(version_id))
        @pop_version()
    else
      exists = false
      for version in @versions
        if version.version_id == version_id
          exists = true
      if not exists
        throw new ReferenceError("Version #{ version_id } does not exist.")

      latest = @versions[@versions.length - 1]
      while latest.version_id != version_id and @versions.length > 1
        @pop_version()
        latest = @versions[@versions.length - 1]

    @import {
      id: @id
      versions: @versions
    }
    @write()

  # Save this instance and write it to persistant storage.
  save: (callback) ->
    new_obj = @export()
    old_obj = @evolve()
    diff = @diff(new_obj, old_obj)
    
    if Object.keys(diff).length > 0
      @push_version(diff)
      @write(callback)
    else if callback?
      callback()
    return true
  
  # #### Private Methods
  # Compares two objects (old and new) and returns a delta object representing the changes
  diff: (new_obj, old_obj) ->
    save = {}
    
    for key in @constructor.fields
      if not Flakey.util.deep_compare(new_obj[key], old_obj[key])
        switch new_obj[key].constructor
          when Object
            # Use $.extend as a bit of a hack to get a deep copy of the object instead of a reference.
            save[key] = $.extend(true, {}, new_obj[key])
          when Array
            save[key] = $.extend(true, [], new_obj[key])
          when String
            old_obj[key] = if old_obj[key]? then old_obj[key].toString() else ''
            if Flakey.settings.diff_text
              patches = Flakey.diff_patch.patch_make(old_obj[key], new_obj[key])
              save[key] = {
                constructor: 'Patch'
                patch_text: Flakey.diff_patch.patch_toText(patches)
              }
            else
              save[key] = new_obj[key]
          else
            save[key] = new_obj[key]
    return save
  
  # Freeze the instance's current fields into an object and return it.
  export: () ->
    obj = {}
    for field in @constructor.fields
      obj[field] = @[field]
    return obj
  
  # Given a version history and a version_id to stop at, evolve a blank object
  # to the to the state at version_id. If version_id is ommited, evolve over the
  # entire version history. If versions is ommited, get the version history of the
  # current object.
  evolve: (version_id, versions) ->
    obj = {}
    
    if versions == undefined or versions.constructor != Array
      saved = Flakey.models.backend_controller.get(@constructor.model_name, @id)
      versions = if saved? then saved.versions else {}
    
    for rev in versions
      for own key, value of rev.fields
        switch value.constructor
          when 'Patch'
            patches = Flakey.diff_patch.patch_fromText(value.patch_text)
            obj[key] = Flakey.diff_patch.patch_apply(patches, obj[key] || '')[0]
          when Object
            obj[key] = $.extend(true, {}, value)
          when Array
            obj[key] = $.extend(true, [], value)
          else
            obj[key] = value
      if version_id != undefined and version_id == rev.version_id
        return obj
    return obj
  
  # Take a stored object from the backend controller, and loads it's data into this instance
  import: (obj) ->
    @versions = obj.versions
    @id = obj.id
    
    for key in @constructor.fields
      @[key] = undefined
    
    for own key, value of @evolve(undefined, @versions)
      @[key] = value
  
  # Pop a version off the history array
  pop_version: () ->
    if @versions.length > 0
      @versions.pop()
    
  # Push a diff onto the history array
  push_version: (diff) ->
    version_id = Flakey.util.guid()
    version = {
      version_id: version_id,
      time: +(new Date()),
      fields: $.extend(true, {}, diff)
    }
    Object.freeze(version)
    @versions.push(version)
  
  # Write the version history into persistent storage.
  write: (callback) ->
    Flakey.util.async () =>
      Flakey.models.backend_controller.save(@constructor.model_name, @id, @versions)
      if callback? then callback()
      # Trigger the saved event
      event_key = "model_#{ @constructor.model_name.toLowerCase() }_updated"
      Flakey.events.trigger(event_key, undefined)


# The backend controler takes care of managing multiple storage backends and querying them for data.
# You should **never** need to call any of these methods from outside this file.
class BackendController
  constructor: () ->
    @delim = ':::'
    @backends = {
      memory: {
        log_key: 'flakey-memory-log'
        pending_log: []
        interface: new MemoryBackend()
      }
    }
    
    if Flakey.settings.enabled_local_backend
      @backends['local'] = {
        log_key: 'flakey-local-log'
        pending_log: []
        interface: new LocalBackend()
      }
    
    if Flakey.settings.base_model_endpoint
      @backends['server'] = {
        log_key: 'flakey-server-log'
        pending_log: []
        interface: new ServerBackend()
      }
      
    if Flakey.settings.socketio_server
      @backends['socketio'] = {
        log_key: 'flakey-socketio-log'
        pending_log: []
        interface: new SocketIOBackend()
      }
    
    @read = Flakey.settings.read_backend || 'memory' # Backend to use for read operations
    @load_logs()
    
  # Pass through methods
  all: (name) ->
    return @backends[@read].interface.all(name)
    
  get: (name, id) ->
    return @backends[@read].interface.get(name, id)
    
  find: (name, query) ->
    return @backends[@read].interface.find(name, query, false)
    
  search: (name, re) ->
    return @backends[@read].interface.find(name, re, true)
  
  # Save an item to the backends
  save: (name, id, versions, backends = @backends) ->
    for own bname, backend of backends
      log_msg = 'save' + @delim + JSON.stringify([name, id, versions])
      if backend.pending_log.length
        backend.pending_log.push(log_msg)
        @commit_logs()
        @exec_log()
        return false
      if not backend.interface.save(name, id, versions)
        backend.pending_log.push(log_msg)
        @commit_logs()
        return false
    return true
  
  # Delete an item from the backends
  delete: (name, id, backends = @backends) ->
    for own bname, backend of backends
      log_msg = 'delete' + @delim + JSON.stringify([name, id])
      if backend.pending_log.length
        backend.pending_log.push(log_msg)
        @commit_logs()
        @exec_log()
        return false
      if not backend.interface.delete(name, id)
        backend.pending_log.push(log_msg)
        @commit_logs()
        return false
    return true
  
  # Execute a backlog of transactions
  exec_log: () ->
    for own name, backend of @backends
      log = backend.pending_log
      for msg in log
        if msg?
          action = msg.split(@delim)
          fn = Flakey.models.backend_controller.backends[name].interface[action[0]]
          params = JSON.parse(action[1])
          bends = {}
          bends[name] = backend
          params.push(bends)
          if fn.apply(Flakey.models.backend_controller.backends[name].interface, params)
            backend.pending_log.shift()
          else
            break;
    @commit_logs()
  
  # Write log to localStorage
  commit_logs: (backends = @backends) ->
    for own name, backend of backends
      localStorage[backend.log_key] = JSON.stringify(backend.pending_log)
    return true
  
  # Load logs from localStorage
  load_logs: (backends = @backends) ->
    for own name, backend of backends
      if not localStorage[backend.log_key]?
        break;
      backend.pending_log = JSON.parse(localStorage[backend.log_key])
    return true
      
  # Sync backends
  sync: (name, backends = @backends) ->
    store = {}
    for own bname, backend of backends
      for item in backend.interface.all(name)
        if item.id in Object.keys(store)
          store[item.id].versions = @merge_version_lists(item.versions, store[item.id].versions)
        else
          store[item.id] = item
    
    output = []
    for own key, item of store
      output.push(item)
    
    for own bname, backend of backends
      backend.interface._write(name, output)
      
    # Trigger the saved event
    event_key = "model_#{ name.toLowerCase() }_updated"
    Flakey.events.trigger(event_key, undefined)
  
  # Merge 2 version lists
  merge_version_lists: (a, b) ->
    temp = {}
    for rev in a.concat(b)
      if rev.time in Object.keys(temp)
        if rev.id != temp[rev.time].id
          for own key, value of rev.fields
             temp[rev.time].fields[key] = value
        else
          temp[rev.time] = rev
      else
        temp[rev.time] = rev
    
    keys = Object.keys(temp)
    keys.sort((a, b) -> return a - b)
    
    output = []
    for key in keys
      output.push(temp[key])
    return output
    

# Base object for providing persistance to Model objects.
# This gets extended by other classes for various methods (server, localStorage, etc)
class Backend
  # List all objects from the given store
  all: (name) ->
    store = @_read(name)
    if not store
      return []
    return store
    
  # Delete an item by id
  delete: (name, id) ->
    store = @_read(name)
    index = @_query_by_id(name, id)
    if index == -1
      return true
    store.splice(index, 1)
    return @_write(name, store)
    
  # Find a set of objects from the given store by performing a query on them.
  # Pass in an object of params to compare, ex: {title: ['eq', 'The Hitchhikers Guide'], vol: ['gt', 2]}
  # Only looks at the latest version of an object, not any previous revisions
  find: (name, query, full_text = false) ->
    store = @_read(name)
    set = if full_text then @_search(name, query) else @_query(name, query)
    out = []
    for i in set
      out.push store[i]
    return out
  
  # Get an object from the given store by its id
  get: (name, id) ->
    store = @_read(name)
    index = @_query_by_id(name, id)
    if index == -1
      return undefined
    return store[index]
  
  # Save an object to the store  
  save: (name, id, versions) ->
    store = @_read(name)
    if not store
      store = []
    index = @_query_by_id(name, id)
    obj = {
      id: id,
      versions: versions
    }
    if index == -1
      store.push(obj)
    else
      store[index] = obj
    return @_write(name, store)

  # Query for an index set by performing search
  # This is SLOW
  _query: (name, query) ->
    store = @_read(name)
    if not store
      return []
    
    set = []
    i = 0
    for obj in store
      rendered = @_render_obj(obj)
      match = true
      for own key, value of query
        if rendered[key] != value
          match = false
      if match
        set.push i
      i++
    
    return set
  
  # Query for index by id. Always returns single index, never a set
  _query_by_id: (name, id) ->
    store = @_read(name)
    if not store
      return -1
    i = 0
    for obj in store
      if obj.id == id
        return i
      i++
    return -1
  
  # Render the latest version of an object by evolving it through all its versions
  _render_obj: (obj) ->
    output = {}
    for rev in obj.versions
      for own key, value of rev.fields
        switch value.constructor
          when 'Patch'
            patches = Flakey.diff_patch.patch_fromText(value.patch_text)
            obj[key] = Flakey.diff_patch.patch_apply(patches, obj[key] || '')[0]
          when Object
            obj[key] = $.extend(true, {}, value)
          when Array
            obj[key] = $.extend(true, [], value)
          else
            obj[key] = value
    return obj
  
  # Full Text Search
  _search: (name, query) ->
    store = @_read(name)
    if not store
      return []
      
    for own key, value of query
      query[key] = new RegExp(value, "g")
    
    set = []
    i = 0
    for obj in store
      rendered = @_render_obj(obj)
      match = false
      for own key, value of query
        if value.exec(rendered[key])
          match = true
      if match
        set.push i
      i++
    
    return set
    

# Virtual Backend that simply stores data in an Object (window.memcache)
class MemoryBackend extends Backend
  constructor: () ->
    if not window.memcache
      window.memcache = {}
    
  _read: (name) ->
    return $.extend(true, [], window.memcache[name])
    
  _write: (name, store) ->
    window.memcache[name] = $.extend(true, [], store)
    return true


# LocalStorage Backend
class LocalBackend extends Backend
  constructor: () ->
    @prefix = 'flakey-'
    
  _read: (name) ->
    if not localStorage[@prefix + name]
      localStorage[@prefix + name] = JSON.stringify([])
    store = JSON.parse(localStorage[@prefix + name])
    return store
    
  _write: (name, store) ->
    localStorage[@prefix + name] = JSON.stringify(store)
    return true
    

# Server storage backend
class ServerBackend extends Backend
  constructor: () ->
    @server_cache = {}
  
  build_endpoint_url: (name, id, params) ->
    url = "#{Flakey.settings.base_model_endpoint}/#{name}"
    if id? then url += "/#{id}"
    if params? and params.constructor == Object
      querystring = Flakey.util.querystring.build(params)
      url += "?#{querystring}"
    return url
    
  # List all objects from the given store
  all: (name) ->
    store = false
    $.ajax({
      async: false
      url: @build_endpoint_url(name)
      dataType: 'json'
      error: () ->
        Flakey.status.server_online = false
      success: (data) ->
        Flakey.status.server_online = true
        store = data
      type: 'GET'
    })

    (@save_to_cache(name, obj.id, obj.versions) for obj in store)
    return store

  # Get an object from the given store by its id
  get: (name, id) ->
    obj = false
    $.ajax({
      async: false
      url: @build_endpoint_url(name, id)
      dataType: 'json'
      error: () ->
        Flakey.status.server_online = false
      success: (data) ->
        Flakey.status.server_online = true
        obj = data
      type: 'GET'
    })

    @save_to_cache(name, obj.id, obj.versions)
    return obj

  # Retreive Object from server cache
  get_from_cache: (name, id) ->
    if @server_cache[name]
      if @server_cache[name][id]
        return @server_cache[name][id]
    return undefined

  # Save an object to the store  
  save: (name, id, versions, force_write) ->
    proposed_obj = {id: id, versions: versions}
    cached_obj = @get_from_cache(name, id)
    
    # Compare cached object to proposed save object
    # Only actually save if they are different, or if force_write flag is true
    if Flakey.util.deep_compare(proposed_obj, cached_obj) and force_write != true
      return true
    
    # Write objects to server
    status = false
    $.ajax({
      async: false
      url: @build_endpoint_url(name, id)
      data: Flakey.util.querystring.build({id: id, versions: JSON.stringify(versions)})
      dataType: 'json'
      error: () ->
        Flakey.status.server_online = false
      success: () ->
        Flakey.status.server_online = true
        status = true
      type: 'POST'
    })
    return status

  # Save object to server_cache
  save_to_cache: (name, id, versions) ->
    @server_cache[name] = @server_cache[name] || {}
    @server_cache[name][id] = $.extend(true, {}, {id: id, versions: versions})

  # Delete an item by id
  delete: (name, id) ->
    status = false
    $.ajax({
      async: false
      url: @build_endpoint_url(name, id)
      dataType: 'json'
      error: () ->
        Flakey.status.server_online = false
      success: () ->
        Flakey.status.server_online = true
        status = true
      type: 'DELETE'
    })
    return status

  _query: (name, query) ->
    throw new TypeError("_query not supported on server backend")

  _query_by_id: (name, id) ->
    throw new TypeError("_query_by_id not supported on server backend")
    
  _read: (name) ->
    return @all(name)

  _write: (name, store) ->
    status = true
    for item in store
      if not @save(name, item.id, item.versions)
        status = false
    return status
    

# Server storage backend
class SocketIOBackend extends Backend
  constructor: () ->
    @status = true
    @socket = window.socket = io.connect(Flakey.settings.socketio_server)
    @server_cache = {}
    
    @socket.on 'sync', (set) =>
      names = []
      for obj in set
        if obj.name not in names
          names.push obj.name
        @save_to_cache(obj.name, obj.id, obj.versions)
            
      for name in names
        Flakey.models.backend_controller.sync(name)
      
    @socket.emit 'fetch_all'

  # List all objects from the given store
  all: (name) ->
    store = []
    @server_cache[name] = @server_cache[name] || {}
    (store.push(@get_from_cache(name, id)) for id in Object.keys(@server_cache[name]))
    return store

  # Get an object from the given store by its id
  get: (name, id) ->
    return @get_from_cache(name, id)

  # Retreive Object from server cache
  get_from_cache: (name, id) ->
    if @server_cache[name]
      if @server_cache[name][id]
        return @server_cache[name][id]
    return undefined

  # Save an object to the store  
  save: (name, id, versions, force_write) ->
    proposed_obj = {id: id, versions: versions}
    cached_obj = @get_from_cache(name, id)
    
    # Compare cached object to proposed save object
    # Only actually save if they are different, or if force_write flag is true
    if Flakey.util.deep_compare(proposed_obj, cached_obj) and force_write != true
      return true

    # Write objects to server
    @socket.emit 'write', {name: name, id: id, versions: versions}, () =>
      @save_to_cache name, id, versions
    return @status

  # Save object to server_cache
  save_to_cache: (name, id, versions) ->
    @server_cache[name] = @server_cache[name] || {}
    @server_cache[name][id] = $.extend(true, {}, {id: id, versions: versions})

  # Delete an item by id
  delete: (name, id) ->
    @socket.emit('delete', {name: name, id: id})
    return @status

  _query: (name, query) ->
    throw new TypeError("_query not supported on socketio backend")

  _query_by_id: (name, id) ->
    throw new TypeError("_query_by_id not supported on socketio backend")

  _read: (name) ->
    return @all(name)

  _write: (name, store) ->
    status = true
    for item in store
      if not @save(name, item.id, item.versions)
        status = false
    return status

# Export into the main flakey object
Flakey.models = {
  Model: Model,
  BackendController: BackendController,
  backend_controller: null
}
