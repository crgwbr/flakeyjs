(function() {
  this.ecoTemplates || (this.ecoTemplates = {});
  this.ecoTemplates["editor"] = function(__obj) {
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
        var saved;
      
        __out.push('<div>\n  <input type="text" name="name" id="name" value="');
      
        __out.push(__sanitize(this.note.name || "Name..."));
      
        __out.push('" />\n  <textarea name="content" id="content">');
      
        __out.push(__sanitize(this.note.content || "Type you note here..."));
      
        __out.push('</textarea>\n    \n  <input type="button" id="save-note" name="save-note" value="Save Note" />\n  \n  ');
      
        if (this.note.versions.length > 0) {
          __out.push('\n    ');
          saved = new Date(this.note.versions[this.note.versions.length - 1].time);
          __out.push('\n    <div id="last-saved">Last saved on: ');
          __out.push(__sanitize(saved.toLocaleString()));
          __out.push('</div>\n  ');
        }
      
        __out.push('\n  \n  ');
      
        if (this.note.versions.length > 1) {
          __out.push('\n    <div id="history">\n      <label for="history-slider">History</label>\n      <input id="history-slider" name="history-slider" type="range" min="0" max="');
          __out.push(__sanitize(this.note.versions.length - 1));
          __out.push('" step="1" value="');
          __out.push(__sanitize(this.note.versions.length - 1));
          __out.push('" />\n    </div>\n    <div id="when"></div>\n  ');
        }
      
        __out.push('\n  \n  <input type="button" id="delete-note" name="delete-note" value="Delete Note" />\n</div>');
      
      }).call(this);
      
    }).call(__obj);
    __obj.safe = __objSafe, __obj.escape = __escape;
    return __out.join('');
  };
}).call(this);
