# ==========================================
# Flakey.js Models
# Craig Weber
# ==========================================


class Model
  @model_name: null
  @fields: ['id']
  
  @objects: {
    constructor: @
    
    # Query for a single object by id
    get: (id) ->
      obj = Flakey.models.backend_controller.get(@constructor.model_name, id)
      if not obj
        return undefined
      m = new @constructor()
      m.import(obj)
      return m
    
    # Get all objects
    all: () ->
      set = []
      for obj in Flakey.models.backend_controller.all(@constructor.model_name)
        m = new @constructor()
        m.import(obj)
        set.push(m)
      return set
  }
  
  constructor: () ->
    @id = Flakey.util.guid()
    @versions = []
    
  diff: (new_obj, old_obj) ->
    save = {}
    for key in Object.keys(new_obj)
      if new_obj[key] != old_obj[key]
        if new_obj[key].constructor == String
          old_obj[key] = if old_obj[key]? then old_obj[key].toString() else ""
        if new_obj[key].constructor == String and old_obj[key].constructor == String and Flakey.settings.diff_text
          patches = Flakey.diff_patch.patch_make(old_obj[key], new_obj[key])
          save[key] = {
            constructor: "Patch"
            patch_text: Flakey.diff_patch.patch_toText(patches)
          }
        else
          save[key] = new_obj[key]
    return save
  
  export: () ->
    obj = {}
    for field in @constructor.fields
      obj[field] = @[field]
    return obj
    
  evolve: (version_id) ->
    obj = {}
    for rev in @versions
      for own key, value of rev.fields
        if value.constructor == "Patch"
          patches = Flakey.diff_patch.patch_fromText(value.patch_text)
          obj[key] = Flakey.diff_patch.patch_apply(patches, obj[key] || "")[0]
        else
          obj[key] = value
      if version_id != undefined and version_id == rev.verson_id
        return obj
    return obj
    
  import: (obj) ->
    @versions = obj.versions
    @id = obj.id
    for own key, value of @evolve()
      @[key] = value
    
  push_version: (diff) ->
    version_id = Flakey.util.guid()
    @versions.push({
      version_id: version_id,
      time: +(new Date()),
      fields: diff
    })
    
  save: () ->
    new_obj = @export()
    old_obj = @evolve()
    diff = @diff(new_obj, old_obj)
    # Don't save empty versions
    if Object.keys(diff).length > 0
      @push_version(diff)
      Flakey.models.backend_controller.save(@constructor.model_name, @id, @versions)
    
  delete: () ->
    Flakey.models.backend_controller.delete(@constructor.model_name, @id)


class BackendController
  constructor: () ->
    @delim = ":::"
    @backends = {
      memory: {
        log_key: 'flakey-memory-log'
        pending_log: []
        interface: new MemoryBackend()
      }
      local: {
        log_key: 'flakey-local-log'
        pending_log: []
        interface: new LocalBackend()
      }
    }
    @read = Flakey.settings.read_backend || 'memory' # Backend to use for read operations
    @load_logs()
    
  # Pass through methods
  all: (name) ->
    return @backends[@read].interface.all(name)
    
  get: (name, id) ->
    return @backends[@read].interface.get(name, id)
    
  find: (name, query) ->
    return @backends[@read].interface.find(name, query)
    
  save: (name, id, versions, backends = @backends) ->
    for own bname, backend of backends
      log_msg = "save" + @delim + JSON.stringify([name, id, versions])
      if backend.pending_log.length
        backend.pending_log.push(log_msg)
        @commit_logs()
        @exec_log({bname: backend})
        return false
      if not backend.interface.save(name, id, versions)
        backend.pending_log.push(log_msg)
        @commit_logs()
        return false
    return true
      
  delete: (name, id, backends = @backends) ->
    for own bname, backend of backends
      log_msg = "delete" + @delim + JSON.stringify([name, id])
      if backend.pending_log.length
        backend.pending_log.push(log_msg)
        @commit_logs()
        @exec_log({name: backend})
        return false
      if not backend.interface.delete(name, id)
        backend.pending_log.push(log_msg)
        @commit_logs()
        return false
    return true
  
  # Log methods
  exec_log: (backends = @backends) ->
    for own name, backend of backends
      while msg = backend.pending_log.shift()
        action = @[msg.split(@delim)]
        fn = action[0]
        params = JSON.parse(action[1])
        params.push({name: backend})
        if not action.apply(@, params)
          backend.pending_log.unshift(msg)
          break;
        @commit_logs()
          
  commit_logs: (backends = @backends) ->
    for own name, backend of backends
      localStorage[backend.log_key] = JSON.stringify(backend.pending_log)
    return true
      
  load_logs: (backends = @backends) ->
    for own name, backend of backends
      if not localStorage[backend.log_key]?
        break;
      backend.pending_log = JSON.parse(localStorage[backend.log_key])
    return true
      
  # Backend Sync
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
  
  # Get an object from the given store by its id
  get: (name, id) ->
    store = @_read(name)
    index = @_query_by_id(name, id)
    if index == -1
      return undefined
    return store[index]
  
  # Find a set of objects from the given store by performing a query on them.
  # Pass in an object of params to compare, ex: {title: ['eq', 'The Hitchhikers Guide'], vol: ['gt', 2]}
  # Only looks at the latest version of an object, not any previous revisions
  find: (name, query) ->
    store = @_read(name)
    iset = @_query(name, query)
    set = []
    for i in iset
      set.push(store[i])
    return set
  
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
    
  # Delete an item by id
  delete: (name, id) ->
    store = @_read(name)
    index = @_query_by_id(name, id)
    if index == -1
      return true
    store.splice(index, 1)
    return @_write(name, store)

  # Query for index set by performing search
  # This is SLOW
  _query: (name, query) ->
    store = @_read(name)
    if not store
      return []
    set = []
    i = 0
    for obj in store
      rendered = @_render_obj(obj)
      for own key, value of query
        if rendered[key] == value
          set.push(i)
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
        if value.constructor == "Patch"
          patches = Flakey.diff_patch.patch_fromText(value.patch_text)
          output[key] = Flakey.diff_patch.patch_apply(patches, obj[key] || "")[0]
        else
          output[key] = value
    return output
    

# Virtual Backend that simply stores data in an Object (window.memcache)
class MemoryBackend extends Backend
  constructor: () ->
    if not window.memcache
      window.memcache = {}
    
  _read: (name) ->
    return window.memcache[name]
    
  _write: (name, store) ->
    window.memcache[name] = store
    return true


# LocalStorage Backend
class LocalBackend extends Backend
  constructor: () ->
    @prefix = "flakey-"
    
  _read: (name) ->
    if not localStorage[@prefix + name]
      localStorage[@prefix + name] = JSON.stringify([])
    store = JSON.parse(localStorage[@prefix + name])
    return store
    
  _write: (name, store) ->
    localStorage[@prefix + name] = JSON.stringify(store)
    return true


Flakey.models = {
  Model: Model,
  backend_controller: new BackendController()
}
