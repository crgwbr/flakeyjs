(function() {
  var $, Flakey, MainController, MainStack, NoteEditor, NoteSelector, models,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  Flakey = require('./flakey');

  $ = Flakey.$;

  models = require('./models');

  NoteSelector = (function(_super) {

    __extends(NoteSelector, _super);

    function NoteSelector(config) {
      this.select_note = __bind(this.select_note, this);      this.id = 'note-selector';
      this.class_name = 'note-selector view';
      this.actions = {
        'click li.note': 'select_note'
      };
      NoteSelector.__super__.constructor.call(this, config);
      this.tmpl = Flakey.templates.get_template('selector', require('./templates/selector'));
    }

    NoteSelector.prototype.render = function() {
      var context;
      context = {
        selected: this.query_params.id,
        notes: models.Note.objects.all()
      };
      return this.html(this.tmpl.render(context));
    };

    NoteSelector.prototype.select_note = function(event) {
      var merge, selected_note;
      this.container.children('ul').children('li.note').removeClass('selected');
      selected_note = $(event.target);
      selected_note.addClass('selected');
      Flakey.util.querystring.update({
        id: selected_note.attr('id')
      }, merge = true);
      return event.preventDefault();
    };

    return NoteSelector;

  })(Flakey.controllers.Controller);

  NoteEditor = (function(_super) {

    __extends(NoteEditor, _super);

    function NoteEditor(config) {
      this.evolve = __bind(this.evolve, this);
      this.delete_note = __bind(this.delete_note, this);
      this.save_note = __bind(this.save_note, this);      this.id = 'note-editor';
      this.class_name = 'note-editor view';
      this.actions = {
        'click #save-note': 'save_note',
        'click #delete-note': 'delete_note',
        'change #history-slider': 'evolve'
      };
      NoteEditor.__super__.constructor.call(this, config);
      this.tmpl = Flakey.templates.get_template('editor', require('./templates/editor'));
    }

    NoteEditor.prototype.render = function() {
      var context;
      context = {};
      context.note = models.Note.objects.get(this.query_params.id);
      if (context.note === void 0 || this.query_params.id === 'new') {
        context.note = new models.Note();
      }
      this.html(this.tmpl.render(context));
      this.unbind_actions();
      return this.bind_actions();
    };

    NoteEditor.prototype.save_note = function(event) {
      var note;
      note = models.Note.objects.get(this.query_params.id);
      if (note === void 0) {
        note = new models.Note();
        note.id = $('#note-id').val();
      }
      note.name = $('#name').val();
      note.content = $('#content').val();
      note.save();
      Flakey.util.querystring.update({
        id: note.id
      });
      this.html(this.tmpl.render({
        note: note
      }));
      this.unbind_actions();
      return this.bind_actions();
    };

    NoteEditor.prototype.delete_note = function(event) {
      var id, note;
      note = models.Note.objects.get(this.query_params.id);
      if (!(note != null)) return;
      id = note.id;
      if (!confirm("Are you sure you'd like to delete this note?")) return;
      note["delete"]();
      id = 'new';
      Flakey.util.querystring.update({
        id: id
      });
      this.unbind_actions();
      return this.bind_actions();
    };

    NoteEditor.prototype.evolve = function() {
      var note, time, version, version_id, version_index;
      version_index = parseInt($('#history-slider').val());
      note = models.Note.objects.get(this.query_params.id);
      version_id = note.versions[version_index].version_id;
      time = new Date(note.versions[version_index].time);
      version = note.evolve(version_id);
      $('#name').val(version.name);
      $('#content').val(version.content);
      $('#when').html(time.toLocaleString());
      this.unbind_actions();
      return this.bind_actions();
    };

    return NoteEditor;

  })(Flakey.controllers.Controller);

  MainController = (function(_super) {

    __extends(MainController, _super);

    function MainController(config) {
      this.id = 'simple-note';
      this.class_name = 'controller';
      MainController.__super__.constructor.call(this, config);
      this.append(NoteSelector, NoteEditor);
    }

    return MainController;

  })(Flakey.controllers.Controller);

  MainStack = (function(_super) {

    __extends(MainStack, _super);

    function MainStack(config) {
      this.id = 'main-stack';
      this.class_name = 'stack';
      this.controllers = {
        'main': MainController
      };
      this.routes = {
        '^/notes$': 'main'
      };
      this["default"] = '/notes';
      MainStack.__super__.constructor.call(this, config);
    }

    return MainStack;

  })(Flakey.controllers.Stack);

  module.exports = {
    MainStack: MainStack
  };

}).call(this);
