# # Flakey.js
# See AUTHORS file for credits
#
# Flakey.js is compiled by concat'ing the src 
# files in this directory in the following order:
#
# 1. flakey.coffee
# 2. util.coffee
# 3. models.coffee
# 4. controllers.coffee
# 5. views.coffee
# 6. exports.coffee
#
# This assembled file is then saved in `../flakey.coffee`
# and compiled into `../flakey.js` and `../flakey.min.js`

# ## Basic Setup
Flakey = {
  diff_patch: new diff_match_patch()
  settings: {
    diff_text: true
    container: undefined
    read_backend: 'memory'
    base_model_endpoint: null #'/api'
    socketio_server: null
    enabled_local_backend: true
  }
  status: {
    server_online: undefined 
  }
}

# Put JQuery into No-Conflict mode, so that we don't interfere with any other library's
jQuery.noConflict()
$ = Flakey.$ = jQuery

# Make JSON accessible too
JSON = Flakey.JSON = JSON

# Flakey's "contructor." This should be called on page load to customize settings and
# init the model backend controller.
Flakey.init = (config) ->
  # Setup config
  for own key, value of config
    Flakey.settings[key] = value
  
  # Init this now so the new settings take effect
  Flakey.models.backend_controller = new Flakey.models.BackendController()


# ## Common Utility Functions

Flakey.util = {
  # Run a function asynchronously
  async: (fn) ->
    setTimeout(fn, 0)
    
  # Deep Compare 2 objects, recursing down through arrays and objects so 
  # that we can compare only primitive types. Return true if they are equal
  deep_compare: (a, b) ->
    if typeof a != typeof b
      return false
    
    compare_objects = (a, b) ->
      for key, value of a
        if not b[key]?
          return false
      
      for key, value of b
        if not a[key]?
          return false
      
      for key, value of a
        if value
          switch typeof value
            when 'object'
              if not compare_objects(value, b[key])
                return false
            else
              if value != b[key]
                return false
        else
          if b[key]
            return false
      
      return true
    
    switch typeof a
      when 'object'
        if not compare_objects(a, b)
          return false
      else
        if a != b
          return false
    
    return true
  
  # GUID function from [spine.js](https://github.com/maccman/spine/blob/master/src/spine.coffee)
  guid: () ->
    guid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    guid = guid.replace(/[xy]/g, (c) ->
      r = Math.random() * 16 | 0
      if c == 'x'
        v = r 
      else 
        v = r & 3 | 8
      v.toString(16).toUpperCase()
      return v
    )
    return guid
    
  # Return current URL hash
  get_hash: () ->
    hash = window.location.hash
    if hash.indexOf('#') == 0
      hash = hash.slice(1)
    return hash

  # ### Querystring functions
  querystring : {
    # Parse a querystring and return an obj of key/values
    parse: (str) ->
      if not str or str.constructor != String
        return {}
      pairs = str.split('&')
      params = {}
      for pair in pairs
        pair = pair.split('=')
        key = decodeURIComponent(pair[0])
        value = decodeURIComponent(pair[1])
        params[key] = value
      return params
      
    # Build a querystring out of an obj
    build: (params) ->
      if not params or params.constructor != Object
        return ''
      pairs = []
      for own key, value of params
        pairs.push "#{encodeURIComponent(key)}=#{encodeURIComponent(value)}"
      return pairs.join('&')
      
    # Update the page's current querystring.
    # Setting merge to true will add your params to the current querystring. 
    # By default, your params wipe out the current querystring.
    update: (params, merge = false) ->
      hash = Flakey.util.get_hash()
      if hash.indexOf('?')
        hash = hash.split('?')
        location = hash[0]
        query = Flakey.util.querystring.parse(hash[1])
      else
        location = hash
        query = {}
      if merge
        $.extend(query, params)
      else
        query = params
      window.location.hash = "#{location}?#{Flakey.util.querystring.build(query)}"
  }
}

  
# ### Basic Observer Event System
class Events
  events: {}
  
  # Register a new function to be triggered by the given event. You may optionally provide a namespace
  # to protect you app's events.
  register: (event, fn, namespace = 'flakey') ->
    if @events[namespace] == undefined
      @events[namespace] = {}
    if @events[namespace][event] == undefined
      @events[namespace][event] = []
    @events[namespace][event].push(fn)
    return @events[namespace][event]
  
  # Trigger an event by passing it's name and optionally the namespace and data to send to each listening function
  trigger: (event, namespace = 'flakey', data = {}) ->
    if @events[namespace] == undefined
      @events[namespace] = {}
    if @events[namespace][event] == undefined
      return
    output = []
    for fn in @events[namespace][event]
      output.push(fn(event, namespace, data))
    return output
  
  # Wipeout all registered functions from a namesapce. Dangerous.
  clear: (namespace = 'flakey') ->
    @events[namespace] = {}

Flakey.events = new Events()


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


# ## Controller Code

# Subclass this to make controllers for your apps
class Controller  
  constructor: (config = {}) ->
    @active = @active || false
    @actions = @actions || {}
    @id = @id || ''
    @class_name = @class_name || ''
    @parent = @parent || null
    @container = @container || null
    @container_html = @container_html || ''
    @subcontrollers = @subcontrollers || []
    @query_params = @query_params || {}
    
    # Build an HTML container to hold this controller
    @container = $(document.createElement('div'))
    @container.html(@container_html)
    @parent = config.parent || Flakey.settings.container
    @parent.append(@container)
    
    @container.attr('id', @id)
    for name in @class_name.split(' ')
      @container.addClass(name)
  
  # Append another controller to this one. It will always mimic the active/passive state of this controller
  append: () ->
    for Contr in arguments
      contr = new Contr({parent: @parent})
      @subcontrollers.push(contr)
  
  # Just a stub
  render: () ->
    @html('')
  
  # Bind actions to JQuery events    
  bind_actions: () ->
    for own key, fn of @actions
      key_parts = key.split(' ')
      action = key_parts.shift()
      selector = key_parts.join(' ')
      $(selector).bind(action, @[fn])
  
  # Unbind actions from JQuery events
  unbind_actions: () ->
    for own key, fn of @actions
      key_parts = key.split(' ')
      action = key_parts.shift()
      selector = key_parts.join(' ')
      $(selector).unbind(action)
  
  # Set the container html to the given string. Generally you can pass the output of a template render right into this.
  html: (htm) ->
    @container_html = htm
    @container.html(@container_html)
    Flakey.events.trigger('html_updated')
  
  # Make this controller active by setting its active class and binding events
  make_active: () ->
    @active = true
    @render()
    @bind_actions()
    @container.removeClass('passive').addClass('active')
    for sub in @subcontrollers
      sub.make_active()
    
  # Make this controller inactive and unbind its events.
  make_inactive: () ->
    @active = false
    @unbind_actions()
    @container.removeClass('active').addClass('passive')
    for sub in @subcontrollers
      sub.make_inactive()
  
  # Set the @query_params attribute
  set_queryparams: (params) ->
    @query_params = params
    for sub in @subcontrollers
      sub.set_queryparams(params)
      

# Subclass a stack to manage a stack of controllers and make sure only one is ever visible at a time.
# Very similar interface to an actual controller
class Stack
  constructor: (config = {}) ->
    @id = @id || ''
    @class_name = @class_name || ''
    @active = @active || false
    @controllers = @controllers || {}
    @routes = @routes || {}
    @default = @default || ''
    @active_controller = @active_controller || ''
    @parent = @parent || null
    @query_params = @query_params || {}
    
    @container = $(document.createElement('div'))
    @container.attr('id', @id)
    for name in @class_name.split(' ')
      @container.addClass(name)
    @container.html(@container_html)
    @parent = config.parent || Flakey.settings.container
    @parent.append(@container)
    
    for own name, contr of @controllers
      @controllers[name] = new contr({parent: @container})
    
    # Make sure we resolve a controller any time the location hash changes.
    window.addEventListener('hashchange', @resolve, false)
    
  # Resolve the location hash to a controller and make it active
  resolve: () =>
    hash = Flakey.util.get_hash()
    
    new_controller = undefined
    if hash.length > 0
      if hash.indexOf('?') != -1
        hash = hash.split('?')
        location = hash[0]
        querystring = hash[1]
      else
        location = hash
        querystring = ''
      new_controller = undefined
      for own route, controller_name of @routes
        regex = new RegExp(route)
        if location.match(route)
          new_controller = controller_name
    
    if not new_controller
      window.location.hash = "##{@default}"
      return
    
    @active_controller = new_controller
    
    # Parse query params from the hash and send them to the active controller
    @controllers[@active_controller].set_queryparams(Flakey.util.querystring.parse(querystring))
    
    # Make all the other controllers inactive
    for own name, controller of @controllers
      if name != @active_controller
        @controllers[name].make_inactive()
        
    if @active
      @controllers[@active_controller].make_active()
      @controllers[@active_controller].render()
        
    return @controllers[@active_controller]
  
  # Make this stack active
  make_active: () ->
    @resolve()
    if @controllers[@active_controller] != undefined
      @controllers[@active_controller].make_active()
      @controllers[@active_controller].render()
    @active = true
        
  # Make this stack inactive
  make_inactive: () ->
    if @controllers[@active_controller] != undefined
      @controllers[@active_controller].make_inactive()
    @active = false
  
  set_queryparams: (params) ->
    @query_params = params
  
    

Flakey.controllers = {
  Stack: Stack,
  Controller: Controller
}

# ## Basic wrapper around Eco templates

class Template
  constructor: (eco, name) ->
    @eco = eco
    @name = name
    
  # Render this template with the given context object, return the resulting string
  render: (context = {}) ->
    return @eco(context)

# Call this to load a Flakey.Template object from a compiled eco template.
get_template = (name, tobj) ->
  template = tobj.ecoTemplates[name]
  return new Template(template, name)

Flakey.templates = {
  get_template
  Template: Template
}

# ## CommonJS exports

# Make this available via CommonJS
if module?
  module.exports = Flakey

# Assign it to the window object, if we're in a browser and a window exists.
if window
  window.Flakey = Flakey