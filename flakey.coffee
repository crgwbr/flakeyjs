# ==========================================
# Compiled: Sun Jan 01 2012 22:15:13 GMT-0500 (EST)

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

Flakey = {}

$ = Flakey.$ = require('jqueryify')
JSON = Flakey.JSON = require('jsonify')

if window
  window.Flakey = Flakey


# ==========================================
# Flakey.js Utility Functions
# Craig Weber
# ==========================================


# GUID function from spine.js
# https://github.com/maccman/spine/blob/master/src/spine.coffee
guid = () ->
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


# Return current URL hash
get_hash = () ->
  hash = window.location.hash
  if hash.indexOf('#') == 0
    hash = hash.slice(1)
  return hash
  
  
Flakey.events = new Events()

Flakey.util = {
  guid: guid,
  get_hash: get_hash
}


# ==========================================
# Flakey.js Models
# Craig Weber
# ==========================================


class Model
  constructor: () ->
    @name = null
    @endpoint = null
    @fields = ['id']
    @backends = []
    @id = Flakey.util.guid()
  
  configure: () ->
    args = (arg for arg in arguments)
    @name = args.shift()
    @backends = [(new Local(@name, @id))]
    while field = args.shift()
      @fields.push(field)
      @[field] = null
    return @
  
  export: () ->
    obj = {}
    for field in @fields
      obj[field] = @[field]
    obj.id = @id
    return obj
    
  import: (obj) ->
    for key in obj
      @[key] = obj[key]
    @id = obj.id
    
  save: () ->
    exp = @export()
    for backend in @backends
      backend.save(exp)
    

class Backend
  constructor: (name, id) ->
    @name = name
    @id = id
    @key = "flakey-#{@name}"
    @versions = []
    
  diff: (new_obj) ->
    old_obj = @render()
    save = {}
    for key in Object.keys(new_obj)
      if new_obj[key] != old_obj[key]
        save[key] = new_obj[key]
    return save
    
  export: () ->
    return {
      id: @id,
      versions: @versions
    }
    
  flatten: (rev) ->
    burned = @render(rev)
    @versions = []
    @save(burned)
    
  get_latest_version: () ->
    revs = @get_versions((a, b) -> return (b - a))
    return revs[0]
    
  get_versions: (sort) ->
    sort = sort || (a, b) -> return (a - b)
    return @versions.sort(sort)
    
  import: (obj) ->
    @id = obj.id
    @versions = obj.versions
    
  load: () ->
    console.log("You need to extend this with a persistance method.")
    
  push_version: (obj) ->
    diff = @diff(obj)
    @versions.push(diff)
    return diff
    
  render: (stop) ->
    stop = stop || @get_latest_version()
    obj = {}
    for rev in @get_versions()
      for key in Object.keys(rev)
        obj[key] = rev[key]
      if rev.id == stop
        return obj
    return obj
    
  save: (obj) ->
    console.log("You need to extend this with a persistance method.")
    
        
class Memory extends Backend
  constructor: (name, id) ->
    super(name, id)
    if not window.memcache
      window.memcache = {}
    if not window.memcache[@key]
      window.memcache[@key] = []
    @store = window.memcache[@key]
    @load()
    
  indexOf: (key, value) ->
    i = 0
    for obj in @store
      if obj[key] == value
        return i
      i++
    return -1

  load: () ->
    index = @indexOf('id', @id)
    if index != -1
      @import(@store[index])
    
  save: (obj) ->
    @push_version(obj)
    index = @indexOf('id', @id)
    if index != -1
      @store[index] = @export()
    else
      @store.push @export()
    return true
    
    
class Local extends Backend
  constructor: (name, id) ->
    super(name, id)
    if not localStorage[@key]
      localStorage[@key] = JSON.stringify([])
    @store = JSON.parse(localStorage[@key])
    @load()
    
  indexOf: (key, value) ->
    i = 0
    for obj in @store
      if obj[key] == value
        return i
      i++
    return -1

  load: () ->
    @store = JSON.parse(localStorage[@key])
    index = @indexOf('id', @id)
    if index != -1
      @import(@store[index])
    
  save: (obj) ->
    @push_version(obj)
    index = @indexOf('id', @id)
    if index != -1
      @store[index] = @export()
    else
      @store.push @export()
    localStorage[@key] = JSON.stringify(@store)
    return true


Flakey.models = {
  Model: Model,
  backends: {
    Memory: Memory
  }
}


# ==========================================
# Flakey.js Controllers
# Craig Weber
# ==========================================
  
class Controller
  active: false
  actions: {}
  id: ''
  class_name: ''
  container: null
  container_html: ''
  subcontrollers: []
  
  constructor: (config = {}) ->
    @container = $(document.createElement('div'))
    @container.attr('id', @id)
    for name in @class_name.split(' ')
      @container.addClass(name)
    @container.html(@container_html)
    
    if config['el'] == undefined
      if Flakey.app_container == undefined
        throw new ReferenceError("App container not set.")
    else
      if Flakey.app_container != undefined
        throw new ReferenceError("Cannot Reset top-level app container")
      else  
        Flakey.app_container = config['el']
        @make_active() # Must be the top level controller
        @render()
    
    Flakey.app_container.append(@container)
    
      
  append: (controller) ->
    @subcontrollers.push(controller)
    
  render: () ->
    @html('You should redefined render() in your controller subclass')
      
  bind_actions: () ->
    for own key, fn of @actions
      key_parts = key.split(' ')
      action = key_parts.shift()
      selector = key_part.join(' ')
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
    @container.html(@container_html)
    @bind_actions()
    @container.removeClass('passive').addClass('active')
    @container.html(@container_html)
    for sub in @subcontrollers
      sub.make_active()
    
  make_inactive: () ->
    @active = false
    @unbind_actions()
    @container.removeClass('active').addClass('passive')
    @container.html('')
    for sub in @subcontrollers
      sub.make_inactive()
      
      
class Stack
  active: false
  controllers: {}
  routes: {}
  default: ''
  active_controller: ''
  
  constructor: (config = {}) ->
    top = false
    if config['el'] == undefined
      if Flakey.app_container == undefined
        throw new ReferenceError("App container not set.")
    else
      if Flakey.app_container != undefined
        throw new ReferenceError("Cannot Reset top-level app container")
      else  
        Flakey.app_container = config['el']
        top = true
    
    for name, controller of @controllers
      @controllers[name] = new controller()
              
    if top
      @make_active() # Must be the top level controller
      @resolve()
    
    window.addEventListener('hashchange', @resolve, false)
    
  resolve: () =>
    
    hash = Flakey.util.get_hash()
    hash = hash.split('?')
    location = new RegExp(hash[0])
    querystring = hash[1]
    console.log(location)
    new_controller = null
    for own route, controller_name of @routes
      if route.match(location)
        new_controller = controller_name
    new_controller = new_controller || @default
    
    if @active_controller != new_controller
      @active_controller = new_controller
      for name, controller of @controllers
        if name != @active_controller
          @controllers[name].make_inactive()
      if @active
        @controllers[@active_controller].make_active()
        @controllers[@active_controller].render()
    return @controllers[@active_controller]
  
  make_active: () ->
    if @controllers[@active_controller] != undefined
      @controllers[@active_controller].make_active()
      @controllers[@active_controller].render()
    @active = true
        
  make_inactive: () ->
    if @controllers[@active_controller] != undefined
      @controllers[@active_controller].make_inactive()
    @active = false
  
    

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