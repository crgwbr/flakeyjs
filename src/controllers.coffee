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
      selector = key_parts.join(' ')
      $(selector).unbind(action)
  
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