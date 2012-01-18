(function() {
  var $, Person,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  $ = Flakey.$;

  Person = (function(_super) {

    __extends(Person, _super);

    function Person() {
      Person.__super__.constructor.apply(this, arguments);
    }

    Person.model_name = 'Person';

    Person.fields = ['id', 'first_name', 'last_name', 'email_address', 'phone_number'];

    return Person;

  })(Flakey.models.Model);

  $(document).ready(function() {
    var bdfl, john, settings,
      _this = this;
    localStorage.clear();
    settings = {
      container: $('#qunit-fixture'),
      base_model_endpoint: void 0
    };
    Flakey.init(settings);
    Flakey.models.backend_controller.sync('Person');
    module("Models");
    bdfl = new Person({
      first_name: 'Guido',
      last_name: 'van Rossum'
    });
    stop();
    bdfl.save(function() {
      return start();
    });
    john = new Person({
      first_name: 'John',
      last_name: 'Resig',
      phone_number: '(555) 555-5555'
    });
    stop();
    john.save(function() {
      return start();
    });
    test("Build initial model", function() {
      expect(10);
      equal(bdfl.first_name, 'Guido', 'First Name Matches');
      equal(bdfl.last_name, 'van Rossum', 'Last Name Matches');
      equal(bdfl.email_address, void 0, 'Email Address not yet set');
      equal(bdfl.phone_number, void 0, 'Phone Number not yet set');
      equal(bdfl.versions.length, 1, 'Length of versions array should be 1');
      equal(john.first_name, 'John', 'First Name Matches');
      equal(john.last_name, 'Resig', 'Last Name Matches');
      equal(john.email_address, void 0, 'Email Address not yet set');
      equal(john.phone_number, '(555) 555-5555', 'Phone Number Matches');
      equal(john.versions.length, 1, 'Length of versions array should be 1');
    });
    test("Push a version", function() {
      var _this = this;
      expect(10);
      bdfl.email_address = "test@example.com";
      stop();
      bdfl.save(function() {
        return start();
      });
      equal(bdfl.first_name, 'Guido', 'First Name Matches');
      equal(bdfl.last_name, 'van Rossum', 'Last Name Matches');
      equal(bdfl.email_address, "test@example.com", 'Email Address now set');
      equal(bdfl.phone_number, void 0, 'Phone Number not yet set');
      equal(bdfl.versions.length, 2, 'Length of versions array should be 2');
      equal(john.first_name, 'John', 'First Name Matches');
      equal(john.last_name, 'Resig', 'Last Name Matches');
      equal(john.email_address, void 0, 'Email Address not yet set');
      equal(john.phone_number, '(555) 555-5555', 'Phone Number Matches');
      equal(john.versions.length, 1, 'Length of versions array should be 1');
    });
    test("Test Evolve Model", function() {
      var previous_bdfl, version_id;
      expect(4);
      version_id = bdfl.versions[bdfl.versions.length - 2].version_id;
      previous_bdfl = bdfl.evolve(version_id);
      equal(previous_bdfl.first_name, 'Guido', 'First Name Matches');
      equal(previous_bdfl.last_name, 'van Rossum', 'Last Name Matches');
      equal(previous_bdfl.email_address, void 0, 'Email Address not yet set');
      equal(previous_bdfl.phone_number, void 0, 'Phone Number not yet set');
    });
    test("Test Evolving Model didn't affect original model", function() {
      expect(10);
      equal(bdfl.first_name, 'Guido', 'First Name Matches');
      equal(bdfl.last_name, 'van Rossum', 'Last Name Matches');
      equal(bdfl.email_address, "test@example.com", 'Email Address is set');
      equal(bdfl.phone_number, void 0, 'Phone Number not yet set');
      equal(bdfl.versions.length, 2, 'Length of versions array should be 2');
      equal(john.first_name, 'John', 'First Name Matches');
      equal(john.last_name, 'Resig', 'Last Name Matches');
      equal(john.email_address, void 0, 'Email Address not yet set');
      equal(john.phone_number, '(555) 555-5555', 'Phone Number Matches');
      equal(john.versions.length, 1, 'Length of versions array should be 1');
    });
    return test("Test Popping a version", function() {
      expect(10);
      bdfl.pop_version();
      stop();
      bdfl.save();
      equal(bdfl.first_name, 'Guido', 'First Name Matches');
      equal(bdfl.last_name, 'van Rossum', 'Last Name Matches');
      equal(bdfl.email_address, void 0, 'Email Address not yet set');
      equal(bdfl.phone_number, void 0, 'Phone Number not yet set');
      equal(bdfl.versions.length, 1, 'Length of versions array should be 2');
      equal(john.first_name, 'John', 'First Name Matches');
      equal(john.last_name, 'Resig', 'Last Name Matches');
      equal(john.email_address, void 0, 'Email Address not yet set');
      equal(john.phone_number, '(555) 555-5555', 'Phone Number Matches');
      equal(john.versions.length, 1, 'Length of versions array should be 1');
    });
  });

}).call(this);
