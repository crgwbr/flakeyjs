# ==========================================
# Flakey.js
# Craig Weber
# ==========================================

Flakey = {
  diff_patch: new diff_match_patch()
  settings: {
    diff_text: true
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