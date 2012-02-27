(function() {
  var $, Person;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  $ = Flakey.$;

  Person = (function() {

    __extends(Person, Flakey.models.Model);

    function Person() {
      Person.__super__.constructor.apply(this, arguments);
    }

    Person.model_name = 'Person';

    Person.fields = ['id', 'first_name', 'last_name', 'email_address', 'phone_number'];

    return Person;

  })();

  window.Person = Person;

  $(document).ready(function() {
    var bdfl, john, settings;
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
    bdfl.save();
    john = new Person({
      first_name: 'John',
      last_name: 'Resig',
      phone_number: '(555) 555-5555'
    });
    john.save();
    test("Test Model Versioning", function() {
      var previous_bdfl, version_id, vid;
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
      bdfl.email_address = "test@example.com";
      bdfl.save();
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
      version_id = bdfl.versions[bdfl.versions.length - 2].version_id;
      previous_bdfl = bdfl.evolve(version_id);
      equal(previous_bdfl.first_name, 'Guido', 'First Name Matches');
      equal(previous_bdfl.last_name, 'van Rossum', 'Last Name Matches');
      equal(previous_bdfl.email_address, void 0, 'Email Address not yet set');
      equal(previous_bdfl.phone_number, void 0, 'Phone Number not yet set');
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
      bdfl.rollback(1);
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
      bdfl.email_address = "test@example.com";
      bdfl.save();
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
      vid = bdfl.versions[bdfl.versions.length - 2].version_id;
      bdfl.rollback(vid);
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
    test("Test Model syncing and persistance", function() {
      var local, local_copy, mem_copy;
      mem_copy = $.extend({}, window.memcache);
      window.memcache = {};
      deepEqual(window.memcache, {}, "Memcache is blank");
      notDeepEqual(mem_copy, window.memcache, "Memcache not equal to memcopy");
      Flakey.models.backend_controller.sync('Person');
      deepEqual(window.memcache, mem_copy, "Sync restored Memcache");
      local_copy = localStorage['flakey-Person'];
      localStorage['flakey-Person'] = "";
      deepEqual(localStorage['flakey-Person'], "", "LocalStorage is blank");
      notDeepEqual(local_copy, localStorage['flakey-Person'], "LocalStorage not equal to local_copy");
      Flakey.models.backend_controller.sync('Person');
      deepEqual(local_copy, localStorage['flakey-Person'], "Sync restored LocalStorage");
      local = {
        Person: Flakey.JSON.parse(localStorage['flakey-Person'])
      };
      return deepEqual(window.memcache, local, "LocalStorage and window.memcache are equal");
    });
    module("Util Functions");
    test("Test Deep Compare", function() {
      var local;
      local = {
        Person: Flakey.JSON.parse(localStorage['flakey-Person'])
      };
      deepEqual(window.memcache, local, "LocalStorage and window.memcache are equal");
      ok(Flakey.util.deep_compare(local, window.memcache), "Deep Compare works for equal objects");
      return ok(!Flakey.util.deep_compare({
        'hello': 'this is equal'
      }, window.memcache), "Deep Compare works for non-equal objects");
    });
    return test("Test Event System", function() {
      expect(1);
      Flakey.events.register('test', function() {
        return ok(true, 'Event system trigger registered event');
      });
      Flakey.events.trigger('test');
      Flakey.events.trigger('test_2');
      return Flakey.events.trigger('test_2', 'namespace');
    });
  });

}).call(this);
