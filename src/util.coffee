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
