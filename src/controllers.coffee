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
      
      hotkey = ""
      if action in ['keydown', 'keyup', 'keypress']
        hotkey = key_parts.shift()
      if (hotkey.indexOf('#') != -1 or hotkey.indexOf('.') != -1) and hotkey.indexOf('+') == -1
        key_parts.shift(hotkey)
        hotkey = ""
      selector = key_parts.join(' ')
      
      if selector.length <= 0
        selector = document
      
      if hotkey
        $(selector).bind(action, hotkey, @[fn])
      else
        $(selector).bind(action, @[fn])
  
  # Unbind actions from JQuery events
  unbind_actions: () ->
    $(document).unbind()
  
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