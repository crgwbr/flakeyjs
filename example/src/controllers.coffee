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
    @unbind_actions()
    context = {}
    
    if @query_params.id?
      note = models.Note.objects.get(@query_params.id)
    
    if note?
      context.note = note
    else
      context.note = new models.Note()
    
    @html @tmpl.render(context)
    @bind_actions()
    
  save_note: (event) =>
    @unbind_actions()
    if @query_params.id?
      note = models.Note.objects.get(@query_params.id)
    
    if not note
      note = new models.Note()
      
    note.name = $('#name').val()
    note.content = $('#content').val()
    note.save()
    Flakey.util.querystring.update({id: note.id})
    @html @tmpl.render({note: note})
    @bind_actions()
    
  delete_note: (event) =>
    @unbind_actions()
    if @query_params.id?
      note = models.Note.objects.get(@query_params.id)
      
      id = note.id
      if confirm("Are you sure you'd like to delete this note?")
        note.delete()
        id = 'new'
    Flakey.util.querystring.update({id: id})
    @bind_actions()
    
  evolve: () =>
    @unbind_actions()
    version_index = $('#history-slider').val()
    note = models.Note.objects.get(@query_params.id)
    version_id = note.versions[version_index].version_id
    time = new Date(note.versions[version_index].time)
    console.log time.toString()
    
    version = note.evolve(version_id)
    $('#name').val(version.name)
    $('#content').val(version.content)
    $('#when').html(time.toLocaleString())
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