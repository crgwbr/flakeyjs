(function() {
  var $, Flakey, controllers, models;

  Flakey = require('./flakey');

  $ = Flakey.$;

  models = require('./models');

  controllers = require('./controllers');

  $(document).ready(function() {
    var note_app, settings;
    settings = {
      container: $('body'),
      base_model_endpoint: '/api'
    };
    Flakey.init(settings);
    Flakey.models.backend_controller.sync('Note');
    note_app = window.note_app = new controllers.MainStack();
    return note_app.make_active();
  });

}).call(this);
