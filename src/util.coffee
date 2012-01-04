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
