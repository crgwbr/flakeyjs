(function() {
  var Flakey, Note,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  Flakey = require('./flakey');

  Note = (function(_super) {

    __extends(Note, _super);

    function Note() {
      Note.__super__.constructor.apply(this, arguments);
    }

    Note.model_name = 'Note';

    Note.fields = ['id', 'name', 'content'];

    Note.objects.constructor = Note;

    return Note;

  })(Flakey.models.Model);

  module.exports = {
    Note: Note
  };

}).call(this);
