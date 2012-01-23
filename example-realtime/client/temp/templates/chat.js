(function() {
  this.ecoTemplates || (this.ecoTemplates = {});
  this.ecoTemplates["chat"] = function(__obj) {
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
        var message, user, _i, _j, _len, _len2, _ref, _ref2;
      
        __out.push('<div class="chat-window">\n\t<ol>\n\t\t');
      
        _ref = this.messages;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          message = _ref[_i];
          __out.push('\n\t\t<li title="');
          __out.push(__sanitize((new Date(message.sent)).toLocaleString()));
          __out.push('" class="');
          __out.push(__sanitize(message["class"]));
          __out.push('">\n\t\t\t<span class="user">');
          __out.push(__sanitize(message.author));
          __out.push('</span>\n\t\t\t<span class="message">');
          __out.push(__sanitize(message.content));
          __out.push('</span>\n\t\t</li>\n\t\t');
        }
      
        __out.push('\n\t<ol>\n</div>\n\n<div class="chat-entry">\n\t<form action="" method="POST" id="message_form">\n\t\t<input type="text" name="new_message" id="new_message" placeholder="Type a message" />\n\t\t<input type="submit" value="Send" />\n\t</form>\n</div>\n\n<div class="users">\n\t<h2>Current Users</h2>\n\t<ul>\n\t\t');
      
        _ref2 = this.users;
        for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
          user = _ref2[_j];
          __out.push('\n\t\t<li>');
          __out.push(__sanitize(user.name));
          __out.push('</li>\n\t\t');
        }
      
        __out.push('\n\t</ul>\n</div>');
      
      }).call(this);
      
    }).call(__obj);
    __obj.safe = __objSafe, __obj.escape = __escape;
    return __out.join('');
  };
}).call(this);
