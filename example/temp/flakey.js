(function() {
  var $, Backend, BackendController, Controller, Events, Flakey, JSON, LocalBackend, MemoryBackend, Model, Stack, Template, get_template,
    __hasProp = Object.prototype.hasOwnProperty,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Flakey = {
    settings: {
      container: void 0,
      read_backend: 'memory'
    }
  };

  $ = Flakey.$ = require('jqueryify');

  JSON = Flakey.JSON = require('jsonify');

  Flakey.init = function(config) {
    var key, value, _results;
    _results = [];
    for (key in config) {
      if (!__hasProp.call(config, key)) continue;
      value = config[key];
      _results.push(Flakey.settings[key] = value);
    }
    return _results;
  };

  if (window) window.Flakey = Flakey;

  Flakey.util = {
    guid: function() {
      var guid;
      guid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx';
      guid = guid.replace(/[xy]/g, function(c) {
        var r, v;
        r = Math.random() * 16 | 0;
        if (c === 'x') {
          v = r;
        } else {
          v = r & 3 | 8;
        }
        v.toString(16).toUpperCase();
        return v;
      });
      return guid;
    },
    get_hash: function() {
      var hash;
      hash = window.location.hash;
      if (hash.indexOf('#') === 0) hash = hash.slice(1);
      return hash;
    },
    querystring: {
      parse: function(str) {
        var key, pair, pairs, params, value, _i, _len;
        if (!str || str.constructor !== String) return {};
        pairs = str.split('&');
        params = {};
        for (_i = 0, _len = pairs.length; _i < _len; _i++) {
          pair = pairs[_i];
          pair = pair.split('=');
          key = decodeURIComponent(pair[0]);
          value = decodeURIComponent(pair[1]);
          params[key] = value;
        }
        return params;
      },
      build: function(params) {
        var key, pairs, value;
        if (!params || params.constructor !== Object) return "";
        pairs = [];
        for (key in params) {
          if (!__hasProp.call(params, key)) continue;
          value = params[key];
          pairs.push("" + (encodeURIComponent(key)) + "=" + (encodeURIComponent(value)));
        }
        return pairs.join('&');
      },
      update: function(params, merge) {
        var hash, location, query;
        if (merge == null) merge = false;
        hash = Flakey.util.get_hash();
        if (hash.indexOf('?')) {
          hash = hash.split('?');
          location = hash[0];
          query = Flakey.util.querystring.parse(hash[1]);
        } else {
          location = hash;
          query = {};
        }
        if (merge) {
          $.extend(query, params);
        } else {
          query = params;
        }
        return window.location.hash = "" + location + "?" + (Flakey.util.querystring.build(query));
      }
    }
  };

  Events = (function() {

    function Events() {}

    Events.prototype.events = {};

    Events.prototype.register = function(event, fn, namespace) {
      if (namespace == null) namespace = "flakey";
      if (this.events[namespace] === void 0) this.events[namespace] = {};
      if (this.events[namespace][event] === void 0) {
        this.events[namespace][event] = [];
      }
      this.events[namespace][event].push(fn);
      return this.events[namespace][event];
    };

    Events.prototype.trigger = function(event, namespace) {
      var fn, output, _i, _len, _ref;
      if (namespace == null) namespace = "flakey";
      if (this.events[namespace] === void 0) this.events[namespace] = {};
      if (this.events[namespace][event] === void 0) return;
      output = [];
      _ref = this.events[namespace][event];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        fn = _ref[_i];
        output.push(fn());
      }
      return output;
    };

    Events.prototype.clear = function(namespace) {
      if (namespace == null) namespace = "flakey";
      return this.events[namespace] = {};
    };

    return Events;

  })();

  Flakey.events = new Events();

  Model = (function() {

    Model.model_name = null;

    Model.fields = ['id'];

    Model.objects = {
      constructor: Model,
      get: function(id) {
        var m, obj;
        obj = Flakey.models.backend_controller.get(this.constructor.model_name, id);
        if (!obj) return;
        m = new this.constructor();
        m["import"](obj);
        return m;
      },
      all: function() {
        var m, obj, set, _i, _len, _ref;
        set = [];
        _ref = Flakey.models.backend_controller.all(this.constructor.model_name);
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          obj = _ref[_i];
          m = new this.constructor();
          m["import"](obj);
          set.push(m);
        }
        return set;
      }
    };

    function Model() {
      this.id = Flakey.util.guid();
      this.versions = [];
    }

    Model.prototype.diff = function(new_obj, old_obj) {
      var key, save, _i, _len, _ref;
      save = {};
      _ref = Object.keys(new_obj);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        key = _ref[_i];
        if (new_obj[key] !== old_obj[key]) save[key] = new_obj[key];
      }
      return save;
    };

    Model.prototype["export"] = function() {
      var field, obj, _i, _len, _ref;
      obj = {};
      _ref = this.constructor.fields;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        field = _ref[_i];
        obj[field] = this[field];
      }
      return obj;
    };

    Model.prototype.evolve = function(version_id) {
      var key, obj, rev, value, _i, _len, _ref, _ref2;
      obj = {};
      _ref = this.versions;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        rev = _ref[_i];
        _ref2 = rev.fields;
        for (key in _ref2) {
          if (!__hasProp.call(_ref2, key)) continue;
          value = _ref2[key];
          obj[key] = value;
        }
        if (version_id !== void 0 && version_id === rev.verson_id) return obj;
      }
      return obj;
    };

    Model.prototype["import"] = function(obj) {
      var key, value, _ref, _results;
      this.versions = obj.versions;
      this.id = obj.id;
      _ref = this.evolve();
      _results = [];
      for (key in _ref) {
        if (!__hasProp.call(_ref, key)) continue;
        value = _ref[key];
        _results.push(this[key] = value);
      }
      return _results;
    };

    Model.prototype.push_version = function(diff) {
      var version_id;
      version_id = Flakey.util.guid();
      return this.versions.push({
        version_id: version_id,
        time: +(new Date()),
        fields: diff
      });
    };

    Model.prototype.save = function() {
      var diff, new_obj, old_obj;
      new_obj = this["export"]();
      old_obj = this.evolve();
      diff = this.diff(new_obj, old_obj);
      this.push_version(diff);
      return Flakey.models.backend_controller.save(this.constructor.model_name, this.id, this.versions);
    };

    Model.prototype["delete"] = function() {
      return Flakey.models.backend_controller["delete"](this.constructor.model_name, this.id);
    };

    return Model;

  })();

  BackendController = (function() {

    function BackendController() {
      this.delim = ":::";
      this.backends = {
        memory: {
          log_key: 'flakey-memory-log',
          pending_log: [],
          interface: new MemoryBackend()
        },
        local: {
          log_key: 'flakey-local-log',
          pending_log: [],
          interface: new LocalBackend()
        }
      };
      this.read = Flakey.settings.read_backend || 'memory';
      this.load_logs();
    }

    BackendController.prototype.all = function(name) {
      return this.backends[this.read].interface.all(name);
    };

    BackendController.prototype.get = function(name, id) {
      return this.backends[this.read].interface.get(name, id);
    };

    BackendController.prototype.find = function(name, query) {
      return this.backends[this.read].interface.find(name, query);
    };

    BackendController.prototype.save = function(name, id, versions, backends) {
      var backend, bname, log_msg;
      if (backends == null) backends = this.backends;
      for (bname in backends) {
        if (!__hasProp.call(backends, bname)) continue;
        backend = backends[bname];
        console.log(bname);
        log_msg = "save" + this.delim + JSON.stringify([name, id, versions]);
        if (backend.pending_log.length) {
          backend.pending_log.push(log_msg);
          this.commit_logs();
          this.exec_log({
            bname: backend
          });
          return false;
        }
        if (!backend.interface.save(name, id, versions)) {
          backend.pending_log.push(log_msg);
          this.commit_logs();
          return false;
        }
      }
      return true;
    };

    BackendController.prototype["delete"] = function(name, id, backends) {
      var backend, bname, log_msg;
      if (backends == null) backends = this.backends;
      for (bname in backends) {
        if (!__hasProp.call(backends, bname)) continue;
        backend = backends[bname];
        log_msg = "delete" + this.delim + JSON.stringify([name, id]);
        if (backend.pending_log.length) {
          backend.pending_log.push(log_msg);
          this.commit_logs();
          this.exec_log({
            name: backend
          });
          return false;
        }
        if (!backend.interface["delete"](name, id)) {
          backend.pending_log.push(log_msg);
          this.commit_logs();
          return false;
        }
      }
      return true;
    };

    BackendController.prototype.exec_log = function(backends) {
      var action, backend, fn, msg, name, params, _results;
      if (backends == null) backends = this.backends;
      _results = [];
      for (name in backends) {
        if (!__hasProp.call(backends, name)) continue;
        backend = backends[name];
        _results.push((function() {
          var _results2;
          _results2 = [];
          while (msg = backend.pending_log.shift()) {
            action = this[msg.split(this.delim)];
            fn = action[0];
            params = JSON.parse(action[1]);
            params.push({
              name: backend
            });
            if (!action.apply(this, params)) {
              backend.pending_log.unshift(msg);
              break;
            }
            _results2.push(this.commit_logs());
          }
          return _results2;
        }).call(this));
      }
      return _results;
    };

    BackendController.prototype.commit_logs = function(backends) {
      var backend, name;
      if (backends == null) backends = this.backends;
      for (name in backends) {
        if (!__hasProp.call(backends, name)) continue;
        backend = backends[name];
        localStorage[backend.log_key] = JSON.stringify(backend.pending_log);
      }
      return true;
    };

    BackendController.prototype.load_logs = function(backends) {
      var backend, name;
      if (backends == null) backends = this.backends;
      for (name in backends) {
        if (!__hasProp.call(backends, name)) continue;
        backend = backends[name];
        if (!(localStorage[backend.log_key] != null)) break;
        backend.pending_log = JSON.parse(localStorage[backend.log_key]);
      }
      return true;
    };

    BackendController.prototype.sync = function(name, backends) {
      var backend, bname, item, key, output, store, _i, _len, _ref, _ref2, _results;
      if (backends == null) backends = this.backends;
      store = {};
      for (bname in backends) {
        if (!__hasProp.call(backends, bname)) continue;
        backend = backends[bname];
        _ref = backend.interface.all(name);
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          item = _ref[_i];
          if (_ref2 = item.id, __indexOf.call(Object.keys(store), _ref2) >= 0) {
            store[item.id].versions = this.merge_version_lists(item.versions, store[item.id].versions);
          } else {
            store[item.id] = item;
          }
        }
      }
      output = [];
      for (key in store) {
        if (!__hasProp.call(store, key)) continue;
        item = store[key];
        output.push(item);
      }
      _results = [];
      for (bname in backends) {
        if (!__hasProp.call(backends, bname)) continue;
        backend = backends[bname];
        _results.push(backend.interface._write(name, output));
      }
      return _results;
    };

    BackendController.prototype.merge_version_lists = function(a, b) {
      var key, keys, output, rev, temp, value, _i, _j, _len, _len2, _ref, _ref2, _ref3;
      temp = {};
      _ref = a.concat(b);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        rev = _ref[_i];
        if (_ref2 = rev.time, __indexOf.call(Object.keys(temp), _ref2) >= 0) {
          if (rev.id !== temp[rev.time].id) {
            _ref3 = rev.fields;
            for (key in _ref3) {
              if (!__hasProp.call(_ref3, key)) continue;
              value = _ref3[key];
              temp[rev.time].fields[key] = value;
            }
          } else {
            temp[rev.time] = rev;
          }
        } else {
          temp[rev.time] = rev;
        }
      }
      keys = Object.keys(temp);
      keys.sort(function(a, b) {
        return a - b;
      });
      output = [];
      for (_j = 0, _len2 = keys.length; _j < _len2; _j++) {
        key = keys[_j];
        output.push(temp[key]);
      }
      return output;
    };

    return BackendController;

  })();

  Backend = (function() {

    function Backend() {}

    Backend.prototype.all = function(name) {
      var store;
      store = this._read(name);
      if (!store) return [];
      return store;
    };

    Backend.prototype.get = function(name, id) {
      var index, store;
      store = this._read(name);
      index = this._query_by_id(name, id);
      if (index === -1) return;
      return store[index];
    };

    Backend.prototype.find = function(name, query) {
      var i, iset, set, store, _i, _len;
      store = this._read(name);
      iset = this._query(name, query);
      set = [];
      for (_i = 0, _len = iset.length; _i < _len; _i++) {
        i = iset[_i];
        set.push(store[i]);
      }
      return set;
    };

    Backend.prototype.save = function(name, id, versions) {
      var index, obj, store;
      store = this._read(name);
      if (!store) store = [];
      index = this._query_by_id(name, id);
      obj = {
        id: id,
        versions: versions
      };
      console.log(index);
      console.log(obj);
      if (index === -1) {
        store.push(obj);
      } else {
        store[index] = obj;
      }
      console.log(store);
      return this._write(name, store);
    };

    Backend.prototype["delete"] = function(name, id) {
      var index, store;
      store = this._read(name);
      index = this._query_by_id(name, id);
      if (index === -1) return true;
      store.splice(index, 1);
      return this._write(name, store);
    };

    Backend.prototype._query = function(name, query) {
      var i, key, obj, rendered, set, store, value, _i, _len;
      store = this._read(name);
      if (!store) return [];
      set = [];
      i = 0;
      for (_i = 0, _len = store.length; _i < _len; _i++) {
        obj = store[_i];
        rendered = this._render_obj(obj);
        for (key in query) {
          if (!__hasProp.call(query, key)) continue;
          value = query[key];
          if (rendered[key] === value) set.push(i);
        }
        i++;
      }
      return set;
    };

    Backend.prototype._query_by_id = function(name, id) {
      var i, obj, store, _i, _len;
      store = this._read(name);
      if (!store) return -1;
      i = 0;
      for (_i = 0, _len = store.length; _i < _len; _i++) {
        obj = store[_i];
        if (obj.id === id) return i;
        i++;
      }
      return -1;
    };

    Backend.prototype._render_obj = function(obj) {
      var key, value, _ref;
      obj = {};
      _ref = obj.versions;
      for (key in _ref) {
        if (!__hasProp.call(_ref, key)) continue;
        value = _ref[key];
        obj[key] = value;
      }
      return obj;
    };

    return Backend;

  })();

  MemoryBackend = (function(_super) {

    __extends(MemoryBackend, _super);

    function MemoryBackend() {
      if (!window.memcache) window.memcache = {};
    }

    MemoryBackend.prototype._read = function(name) {
      return window.memcache[name];
    };

    MemoryBackend.prototype._write = function(name, store) {
      window.memcache[name] = store;
      return true;
    };

    return MemoryBackend;

  })(Backend);

  LocalBackend = (function(_super) {

    __extends(LocalBackend, _super);

    function LocalBackend() {
      this.prefix = "flakey-";
    }

    LocalBackend.prototype._read = function(name) {
      var store;
      if (!localStorage[this.prefix + name]) {
        localStorage[this.prefix + name] = JSON.stringify([]);
      }
      store = JSON.parse(localStorage[this.prefix + name]);
      return store;
    };

    LocalBackend.prototype._write = function(name, store) {
      localStorage[this.prefix + name] = JSON.stringify(store);
      return true;
    };

    return LocalBackend;

  })(Backend);

  Flakey.models = {
    Model: Model,
    backend_controller: new BackendController()
  };

  Controller = (function() {

    function Controller(config) {
      var name, _i, _len, _ref;
      if (config == null) config = {};
      this.active = this.active || false;
      this.actions = this.actions || {};
      this.id = this.id || '';
      this.class_name = this.class_name || '';
      this.parent = this.parent || null;
      this.container = this.container || null;
      this.container_html = this.container_html || '';
      this.subcontrollers = this.subcontrollers || [];
      this.query_params = this.query_params || {};
      this.container = $(document.createElement('div'));
      this.container.html(this.container_html);
      this.parent = config.parent || Flakey.settings.container;
      this.parent.append(this.container);
      this.container.attr('id', this.id);
      _ref = this.class_name.split(' ');
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        name = _ref[_i];
        this.container.addClass(name);
      }
    }

    Controller.prototype.append = function() {
      var Contr, contr, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = arguments.length; _i < _len; _i++) {
        Contr = arguments[_i];
        contr = new Contr({
          parent: this.parent
        });
        _results.push(this.subcontrollers.push(contr));
      }
      return _results;
    };

    Controller.prototype.render = function() {
      return this.html('');
    };

    Controller.prototype.bind_actions = function() {
      var action, fn, key, key_parts, selector, _ref, _results;
      _ref = this.actions;
      _results = [];
      for (key in _ref) {
        if (!__hasProp.call(_ref, key)) continue;
        fn = _ref[key];
        key_parts = key.split(' ');
        action = key_parts.shift();
        selector = key_parts.join(' ');
        _results.push($(selector).bind(action, this[fn]));
      }
      return _results;
    };

    Controller.prototype.unbind_actions = function() {
      var action, fn, key, key_parts, selector, _ref, _results;
      _ref = this.actions;
      _results = [];
      for (key in _ref) {
        if (!__hasProp.call(_ref, key)) continue;
        fn = _ref[key];
        key_parts = key.split(' ');
        action = key_parts.shift();
        selector = key_part.join(' ');
        _results.push($(selector).unbind(action, this[fn]));
      }
      return _results;
    };

    Controller.prototype.html = function(htm) {
      this.container_html = htm;
      this.container.html(this.container_html);
      return Flakey.events.trigger('html_updated');
    };

    Controller.prototype.make_active = function() {
      var sub, _i, _len, _ref, _results;
      this.active = true;
      this.render();
      this.bind_actions();
      this.container.removeClass('passive').addClass('active');
      _ref = this.subcontrollers;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        sub = _ref[_i];
        _results.push(sub.make_active());
      }
      return _results;
    };

    Controller.prototype.make_inactive = function() {
      var sub, _i, _len, _ref, _results;
      this.active = false;
      this.unbind_actions();
      this.container.removeClass('active').addClass('passive');
      _ref = this.subcontrollers;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        sub = _ref[_i];
        _results.push(sub.make_inactive());
      }
      return _results;
    };

    Controller.prototype.set_queryparams = function(params) {
      var sub, _i, _len, _ref, _results;
      this.query_params = params;
      _ref = this.subcontrollers;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        sub = _ref[_i];
        _results.push(sub.set_queryparams(params));
      }
      return _results;
    };

    return Controller;

  })();

  Stack = (function() {

    function Stack(config) {
      var contr, name, _i, _len, _ref, _ref2;
      if (config == null) config = {};
      this.resolve = __bind(this.resolve, this);
      this.id = this.id || '';
      this.class_name = this.class_name || '';
      this.active = this.active || false;
      this.controllers = this.controllers || {};
      this.routes = this.routes || {};
      this["default"] = this["default"] || '';
      this.active_controller = this.active_controller || '';
      this.parent = this.parent || null;
      this.query_params = this.query_params || {};
      this.container = $(document.createElement('div'));
      this.container.attr('id', this.id);
      _ref = this.class_name.split(' ');
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        name = _ref[_i];
        this.container.addClass(name);
      }
      this.container.html(this.container_html);
      this.parent = config.parent || Flakey.settings.container;
      this.parent.append(this.container);
      _ref2 = this.controllers;
      for (name in _ref2) {
        if (!__hasProp.call(_ref2, name)) continue;
        contr = _ref2[name];
        this.controllers[name] = new contr({
          parent: this.container
        });
      }
      window.addEventListener('hashchange', this.resolve, false);
    }

    Stack.prototype.resolve = function() {
      var controller, controller_name, hash, location, name, new_controller, querystring, regex, route, _ref, _ref2;
      hash = Flakey.util.get_hash();
      new_controller = void 0;
      if (hash.length > 0) {
        if (hash.indexOf('?') !== -1) {
          hash = hash.split('?');
          location = hash[0];
          querystring = hash[1];
        } else {
          location = hash;
          querystring = "";
        }
        new_controller = void 0;
        _ref = this.routes;
        for (route in _ref) {
          if (!__hasProp.call(_ref, route)) continue;
          controller_name = _ref[route];
          regex = new RegExp(route);
          if (location.match(route)) new_controller = controller_name;
        }
      }
      if (!new_controller) {
        window.location.hash = "#" + this["default"];
        return;
      }
      this.active_controller = new_controller;
      this.controllers[this.active_controller].set_queryparams(Flakey.util.querystring.parse(querystring));
      _ref2 = this.controllers;
      for (name in _ref2) {
        if (!__hasProp.call(_ref2, name)) continue;
        controller = _ref2[name];
        if (name !== this.active_controller) {
          this.controllers[name].make_inactive();
        }
      }
      if (this.active) {
        this.controllers[this.active_controller].make_active();
        this.controllers[this.active_controller].render();
      }
      return this.controllers[this.active_controller];
    };

    Stack.prototype.make_active = function() {
      this.resolve();
      if (this.controllers[this.active_controller] !== void 0) {
        this.controllers[this.active_controller].make_active();
        this.controllers[this.active_controller].render();
      }
      return this.active = true;
    };

    Stack.prototype.make_inactive = function() {
      if (this.controllers[this.active_controller] !== void 0) {
        this.controllers[this.active_controller].make_inactive();
      }
      return this.active = false;
    };

    Stack.prototype.set_queryparams = function(params) {
      return this.query_params = params;
    };

    return Stack;

  })();

  Flakey.controllers = {
    Stack: Stack,
    Controller: Controller
  };

  Template = (function() {

    function Template(eco, name) {
      this.eco = eco;
      this.name = name;
    }

    Template.prototype.render = function(context) {
      if (context == null) context = {};
      return this.eco(context);
    };

    return Template;

  })();

  get_template = function(name, tobj) {
    var template;
    template = tobj.ecoTemplates[name];
    return new Template(template, name);
  };

  Flakey.templates = {
    get_template: get_template,
    Template: Template
  };

  module.exports = Flakey;

}).call(this);
