# ==========================================
# Simple Note Taking App
# models.coffee
#
# This file is not part of Flakey.js
# It is just used to illustrate its
# potential use.
# ==========================================

Flakey = require('./flakey') # This path will change depending on where your copy of flakey.js is.

class Note extends Flakey.models.Model
  @model_name: 'Note', 
  @fields: ['id', 'name', 'content']
  @objects.constructor = @
  
module.exports = {
  Note: Note
}