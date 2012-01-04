# ==========================================
# Compiled: Tue Jan 03 2012 20:52:13 GMT-0500 (EST)

# Contents:
#   - src/flakey.coffee
#   - src/util.coffee
#   - src/models.coffee
#   - src/controllers.coffee
#   - src/views.coffee
#   - src/exports.coffee
# ==========================================

# ==========================================
# Flakey.js
# Craig Weber
# ==========================================

Flakey = {
  settings: {
    container: undefined
    read_backend: 'memory'
  }
}

$ = Flakey.$ = require('jqueryify')
JSON = Flakey.JSON = require('jsonify')

Flakey.init = (config) ->
  # Setup config
  for own key, value of config
    Flakey.settings[key] = value
  

if window
  window.Flakey = Flakey


# ==========================================
# Flakey.js Utility Functions
# Craig Weber
# ==========================================


Flakey.util = {
  # GUID function from spine.js
  # https://github.com/maccman/spine/blob/master/src/spine.coffee
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

  # Querystring functions
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
        return ""
      pairs = []
      for own key, value of params
        pairs.push "#{encodeURIComponent(key)}=#{encodeURIComponent(value)}"
      return pairs.join('&')
      
    # Update the page's current querystring
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

  
# Basic Event System
class Events
  events: {}
  
  register: (event, fn, namespace = "flakey") ->
    if @events[namespace] == undefined
      @events[namespace] = {}
    if @events[namespace][event] == undefined
      @events[namespace][event] = []
    @events[namespace][event].push(fn)
    return @events[namespace][event]
    
  trigger: (event, namespace = "flakey") ->
    if @events[namespace] == undefined
      @events[namespace] = {}
    if @events[namespace][event] == undefined
      return
    output = []
    for fn in @events[namespace][event]
      output.push(fn())
    return output
    
  clear: (namespace = "flakey") ->
    @events[namespace] = {}
  
Flakey.events = new Events()


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
      console.log(bname)
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
    console.log index
    console.log obj
    if index == -1
      store.push(obj)
    else
      store[index] = obj
    console.log(store)
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
    obj = {}
    for own key, value of obj.versions
      obj[key] = value
    return obj
    

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


# ==========================================
# Flakey.js Controllers
# Craig Weber
# ==========================================
  
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
    
    @container = $(document.createElement('div'))
    @container.html(@container_html)
    @parent = config.parent || Flakey.settings.container
    @parent.append(@container)
    
    @container.attr('id', @id)
    for name in @class_name.split(' ')
      @container.addClass(name)
      
  append: () ->
    for Contr in arguments
      contr = new Contr({parent: @parent})
      @subcontrollers.push(contr)
    
  render: () ->
    @html('')
      
  bind_actions: () ->
    for own key, fn of @actions
      key_parts = key.split(' ')
      action = key_parts.shift()
      selector = key_parts.join(' ')
      $(selector).bind(action, @[fn])
  
  unbind_actions: () ->
    for own key, fn of @actions
      key_parts = key.split(' ')
      action = key_parts.shift()
      selector = key_part.join(' ')
      $(selector).unbind(action, @[fn])
  
  html: (htm) ->
    @container_html = htm
    @container.html(@container_html)
    Flakey.events.trigger('html_updated')
    
  make_active: () ->
    @active = true
    @render()
    @bind_actions()
    @container.removeClass('passive').addClass('active')
    for sub in @subcontrollers
      sub.make_active()
    
  make_inactive: () ->
    @active = false
    @unbind_actions()
    @container.removeClass('active').addClass('passive')
    for sub in @subcontrollers
      sub.make_inactive()
      
  set_queryparams: (params) ->
    @query_params = params
    for sub in @subcontrollers
      sub.set_queryparams(params)
      
      
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
    
    window.addEventListener('hashchange', @resolve, false)
    
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
        querystring = ""
      new_controller = undefined
      for own route, controller_name of @routes
        regex = new RegExp(route)
        if location.match(route)
          new_controller = controller_name
    
    if not new_controller
      window.location.hash = "##{@default}"
      return
    
    @active_controller = new_controller
    @controllers[@active_controller].set_queryparams(Flakey.util.querystring.parse(querystring))
    
    for own name, controller of @controllers
      if name != @active_controller
        @controllers[name].make_inactive()
        
    if @active
      @controllers[@active_controller].make_active()
      @controllers[@active_controller].render()
        
    return @controllers[@active_controller]
  
  make_active: () ->
    @resolve()
    if @controllers[@active_controller] != undefined
      @controllers[@active_controller].make_active()
      @controllers[@active_controller].render()
    @active = true
        
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

# ==========================================
# Flakey.js Views
# Craig Weber
# ==========================================

class Template
  constructor: (eco, name) ->
    @eco = eco
    @name = name
    
  render: (context = {}) ->
    return @eco(context)
    
get_template = (name, tobj) ->
  template = tobj.ecoTemplates[name]
  return new Template(template, name)

Flakey.templates = {
  get_template
  Template: Template
}

# ==========================================
# Flakey.js Exports
# Craig Weber
# ==========================================

module.exports = Flakey