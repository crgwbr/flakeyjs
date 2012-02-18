# * * * * *
# # Flakey.js
# See AUTHORS file for credits
#
# Flakey.js is compiled by concat'ing the src 
# files in this directory in the following order:
#  - flakey.coffee
#  - util.coffee
#  - models.coffee
#  - controllers.coffee
#  - views.coffee
#  - exports.coffee
# This assembled file is then saved in ../flakey.coffee
# and compiled into ../flakey.js and ../flakey.min.js
# 
# This file is responsible for creating the main Flakey
# object so that util/model/controller modules can 
# later add themselves to it. We also initalize jQuery
# in noconflict mode and assign it to Flakey.$
# * * * * *

# Setup the Flakey object with an instance of diff_match_patch and some default settings.
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
