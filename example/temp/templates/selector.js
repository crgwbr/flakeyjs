(function() {
  this.ecoTemplates || (this.ecoTemplates = {});
  this.ecoTemplates["selector"] = function(__obj) {
    if (!__obj) __obj = {};
    var __out = [], __capture = function(callback) {
      var out = __out, result;
      __out = [];
      callback.call(this);
      result = __out.join('');
      __out = out;
      return __safe(result);
    }, __sanitize = function(value) {
      if (value && value.ecoSafe) {
        return value;
      } else if (typeof value !== 'undefined' && value != null) {
        return __escape(value);
      } else {
        return '';
      }
    }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
    __safe = __obj.safe = function(value) {
      if (value && value.ecoSafe) {
        return value;
      } else {
        if (!(typeof value !== 'undefined' && value != null)) value = '';
        var result = new String(value);
        result.ecoSafe = true;
        return result;
      }
    };
    if (!__escape) {
      __escape = __obj.escape = function(value) {
        return ('' + value)
          .replace(/&/g, '&amp;')
          .replace(/</g, '&lt;')
          .replace(/>/g, '&gt;')
          .replace(/"/g, '&quot;');
      };
    }
    (function() {
      (function() {
        var note, _i, _len, _ref;
      
        __out.push('<ul>\n  <li id="new" class="note ');
      
        __out.push(__sanitize(!(this.selected != null) || this.selected === "new" ? "selected" : ""));
      
        __out.push('">New Note</li>\n  \n  ');
      
        _ref = this.notes;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          note = _ref[_i];
          __out.push('\n    <li id="');
          __out.push(__sanitize(note.id));
          __out.push('" class="note ');
          __out.push(__sanitize((this.selected != null) && note.id.toString() === this.selected.toString() ? "selected" : ""));
          __out.push('">');
          __out.push(__sanitize(note.name));
          __out.push('</li>\n  ');
        }
      
        __out.push('\n</ul>');
      
      }).call(this);
      
    }).call(__obj);
    __obj.safe = __objSafe, __obj.escape = __escape;
    return __out.join('');
  };
}).call(this);
