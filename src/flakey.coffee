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
    base_model_endpoint: null #'/api'
  }
  status: {
    server_online: undefined 
  }
}

jQuery.noConflict();
$ = Flakey.$ = jQuery
JSON = Flakey.JSON = JSON

Flakey.init = (config) ->
  # Setup config
  for own key, value of config
    Flakey.settings[key] = value
  
  # Init this now so the new settings take effect
  Flakey.models.backend_controller = new Flakey.models.BackendController()
  

if window
  window.Flakey = Flakey
