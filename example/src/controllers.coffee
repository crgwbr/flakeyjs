# ==========================================
# Simple Note Taking App
# controllers.coffee
#
# This file is not part of Flakey.js
# It is just used to illustrate its
# potential use.
# ==========================================

Flakey = require('./flakey') # This path will change depending on where your copy of flakey.js is.
$ = Flakey.$

models = require('./models')


class NoteSelector extends Flakey.controllers.Controller
  constructor: (config) ->
    @id = 'note-selector'
    @class_name = 'note-selector view'
    @actions = {
      'click li.note': 'select_note'
    }
    super(config)
    
    @tmpl = Flakey.templates.get_template('selector', require('./templates/selector'))
    
  render: () ->
    context = {
      selected: @query_params.id,
      notes: models.Note.objects.all()
    }
    @html @tmpl.render(context)
    
  select_note: (event) =>
    @container.children('ul').children('li.note').removeClass('selected')
    selected_note = $(event.target)
    selected_note.addClass('selected')
    Flakey.util.querystring.update({id: selected_note.attr('id')}, merge = true)
    event.preventDefault()


class NoteEditor extends Flakey.controllers.Controller
  constructor: (config) ->
    @id = 'note-editor'
    @class_name = 'note-editor view'
    @actions = {
      'click #save-note': 'save_note'
      'click #delete-note': 'delete_note'
    }
    super(config)
    
    @tmpl =  Flakey.templates.get_template('editor', require('./templates/editor'))

  render: () ->
    context = {note: {}}
    if @query_params.id?
      note = models.Note.objects.get(@query_params.id)
    
    if note?
      context.note = note
      
    @html @tmpl.render(context)
    
  save_note: (event) =>
    if @query_params.id?
      note = models.Note.objects.get(@query_params.id)
    
    if not note
      note = new models.Note()
      
    note.name = $('#name').val()
    note.content = $('#content').val()
    note.save()
    Flakey.util.querystring.update({id: note.id})
    
  delete_note: (event) =>
    if @query_params.id?
      note = models.Note.objects.get(@query_params.id)
      
      id = note.id
      if confirm("Are you sure you'd like to delete this note?")
        note.delete()
        id = 'new'
    Flakey.util.querystring.update({id: id})
      


class MainController extends Flakey.controllers.Controller
  constructor: (config) ->
    @id = 'simple-note'
    @class_name = 'controller'
    super(config)
    @append NoteSelector, NoteEditor
    
    
class MainStack extends Flakey.controllers.Stack
  constructor: (config) ->
    @id = 'main-stack'
    @class_name = 'stack'
    @controllers = {
      'main': MainController
    }
    
    @routes = {
      '^/notes$': 'main'
    }
    @default = '/notes'
    
    super(config)
            
    
module.exports = {
  MainStack: MainStack
}