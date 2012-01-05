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
      'change #history-slider': 'evolve'
    }
    super(config)
    
    @tmpl =  Flakey.templates.get_template('editor', require('./templates/editor'))

  render: () ->
    context = {}

    context.note = models.Note.objects.get(@query_params.id)
      
    if context.note == undefined or @query_params.id == 'new'
      context.note = new models.Note()
    
    @html @tmpl.render(context)
    @unbind_actions()
    @bind_actions()
    
  save_note: (event) =>
    note = models.Note.objects.get(@query_params.id)
    
    if note == undefined
      note = new models.Note()
      note.id = $('#note-id').val()
    
    note.name = $('#name').val()
    note.content = $('#content').val()
    note.save()
    Flakey.util.querystring.update({id: note.id})
    @html @tmpl.render({note: note})
    @unbind_actions()
    @bind_actions()
    
  delete_note: (event) =>
    if @query_params.id?
      note = models.Note.objects.get(@query_params.id)
      
      id = note.id
      if confirm("Are you sure you'd like to delete this note?")
        note.delete()
        id = 'new'
    Flakey.util.querystring.update({id: id})
    @unbind_actions()
    @bind_actions()
    
  evolve: () =>
    version_index = parseInt($('#history-slider').val())
    note = models.Note.objects.get(@query_params.id)
    version_id = note.versions[version_index].version_id
    time = new Date(note.versions[version_index].time)
    
    version = note.evolve(version_id)
    $('#name').val(version.name)
    $('#content').val(version.content)
    $('#when').html(time.toLocaleString())
    @unbind_actions()
    @bind_actions()


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