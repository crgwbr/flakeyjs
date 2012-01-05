# ==========================================
# Simple Note Taking App
# index.coffee
#
# This file is not part of Flakey.js
# It is just used to illustrate its
# potential use.
# ==========================================

Flakey = require('./flakey') # This path will change depending on where your copy of flakey.js is.
$ = Flakey.$

models = require('./models')
controllers = require('./controllers')


$(document).ready () ->
  settings = {
    container: $('body')
    base_model_endpoint: '/api'
  }
  Flakey.init(settings)
  
  # Sync models
  Flakey.models.backend_controller.sync('Note')
  
  note_app = window.note_app = new controllers.MainStack()
  note_app.make_active()
  