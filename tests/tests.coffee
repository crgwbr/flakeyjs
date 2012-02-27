$ = Flakey.$

class Person extends Flakey.models.Model
  @model_name: 'Person', 
  @fields: ['id', 'first_name', 'last_name', 'email_address', 'phone_number']
  
window.Person = Person


$(document).ready () ->
  # Make sure were starting fresh
  localStorage.clear()
  
  # Init Flakey.js
  settings = {
    container: $('#qunit-fixture')
    base_model_endpoint: undefined
  }
  Flakey.init(settings)
  
  # Sync models
  Flakey.models.backend_controller.sync('Person')
  
  
  # ========================================================================================
  # Model Tests
  # ========================================================================================
  module "Models"
  
  bdfl = new Person {
    first_name: 'Guido'
    last_name: 'van Rossum'
  }
  bdfl.save()
  
  john = new Person {
    first_name: 'John'
    last_name: 'Resig'
    phone_number: '(555) 555-5555'
  }
  john.save()
  
  test "Test Model Versioning", () ->   
    equal bdfl.first_name, 'Guido', 'First Name Matches'
    equal bdfl.last_name, 'van Rossum', 'Last Name Matches'
    equal bdfl.email_address, undefined, 'Email Address not yet set'
    equal bdfl.phone_number, undefined, 'Phone Number not yet set'
    equal bdfl.versions.length, 1, 'Length of versions array should be 1'
    equal john.first_name, 'John', 'First Name Matches'
    equal john.last_name, 'Resig', 'Last Name Matches'
    equal john.email_address, undefined, 'Email Address not yet set'
    equal john.phone_number, '(555) 555-5555', 'Phone Number Matches'
    equal john.versions.length, 1, 'Length of versions array should be 1'
    
    # Test Pushing a versions
    bdfl.email_address = "test@example.com"
    bdfl.save()
    
    equal bdfl.first_name, 'Guido', 'First Name Matches'
    equal bdfl.last_name, 'van Rossum', 'Last Name Matches'
    equal bdfl.email_address, "test@example.com", 'Email Address now set'
    equal bdfl.phone_number, undefined, 'Phone Number not yet set'
    equal bdfl.versions.length, 2, 'Length of versions array should be 2'
    equal john.first_name, 'John', 'First Name Matches'
    equal john.last_name, 'Resig', 'Last Name Matches'
    equal john.email_address, undefined, 'Email Address not yet set'
    equal john.phone_number, '(555) 555-5555', 'Phone Number Matches'
    equal john.versions.length, 1, 'Length of versions array should be 1'
    
    # Test evolving a previous version
    version_id = bdfl.versions[bdfl.versions.length - 2].version_id # Get Pervious version
    previous_bdfl = bdfl.evolve(version_id)
    
    equal previous_bdfl.first_name, 'Guido', 'First Name Matches'
    equal previous_bdfl.last_name, 'van Rossum', 'Last Name Matches'
    equal previous_bdfl.email_address, undefined, 'Email Address not yet set'
    equal previous_bdfl.phone_number, undefined, 'Phone Number not yet set'
    
    # Test evolve() didn't affect original model
    equal bdfl.first_name, 'Guido', 'First Name Matches'
    equal bdfl.last_name, 'van Rossum', 'Last Name Matches'
    equal bdfl.email_address, "test@example.com", 'Email Address is set'
    equal bdfl.phone_number, undefined, 'Phone Number not yet set'
    equal bdfl.versions.length, 2, 'Length of versions array should be 2'
    equal john.first_name, 'John', 'First Name Matches'
    equal john.last_name, 'Resig', 'Last Name Matches'
    equal john.email_address, undefined, 'Email Address not yet set'
    equal john.phone_number, '(555) 555-5555', 'Phone Number Matches'
    equal john.versions.length, 1, 'Length of versions array should be 1'
    
    # Test Rollback model by number
    bdfl.rollback(1)
    
    equal bdfl.first_name, 'Guido', 'First Name Matches'
    equal bdfl.last_name, 'van Rossum', 'Last Name Matches'
    equal bdfl.email_address, undefined, 'Email Address not yet set'
    equal bdfl.phone_number, undefined, 'Phone Number not yet set'
    equal bdfl.versions.length, 1, 'Length of versions array should be 2'
    equal john.first_name, 'John', 'First Name Matches'
    equal john.last_name, 'Resig', 'Last Name Matches'
    equal john.email_address, undefined, 'Email Address not yet set'
    equal john.phone_number, '(555) 555-5555', 'Phone Number Matches'
    equal john.versions.length, 1, 'Length of versions array should be 1'
    
    # Test Pushing a versions
    bdfl.email_address = "test@example.com"
    bdfl.save()
    
    equal bdfl.first_name, 'Guido', 'First Name Matches'
    equal bdfl.last_name, 'van Rossum', 'Last Name Matches'
    equal bdfl.email_address, "test@example.com", 'Email Address now set'
    equal bdfl.phone_number, undefined, 'Phone Number not yet set'
    equal bdfl.versions.length, 2, 'Length of versions array should be 2'
    equal john.first_name, 'John', 'First Name Matches'
    equal john.last_name, 'Resig', 'Last Name Matches'
    equal john.email_address, undefined, 'Email Address not yet set'
    equal john.phone_number, '(555) 555-5555', 'Phone Number Matches'
    equal john.versions.length, 1, 'Length of versions array should be 1'
    
    # Test Rollback model by version ID
    vid = bdfl.versions[bdfl.versions.length - 2].version_id
    bdfl.rollback(vid)
    
    equal bdfl.first_name, 'Guido', 'First Name Matches'
    equal bdfl.last_name, 'van Rossum', 'Last Name Matches'
    equal bdfl.email_address, undefined, 'Email Address not yet set'
    equal bdfl.phone_number, undefined, 'Phone Number not yet set'
    equal bdfl.versions.length, 1, 'Length of versions array should be 2'
    equal john.first_name, 'John', 'First Name Matches'
    equal john.last_name, 'Resig', 'Last Name Matches'
    equal john.email_address, undefined, 'Email Address not yet set'
    equal john.phone_number, '(555) 555-5555', 'Phone Number Matches'
    equal john.versions.length, 1, 'Length of versions array should be 1'
    return
    
  test "Test Model syncing and persistance", () ->
    mem_copy = $.extend({}, window.memcache)
    window.memcache = {}
    
    deepEqual window.memcache, {}, "Memcache is blank"
    notDeepEqual mem_copy, window.memcache, "Memcache not equal to memcopy"
    
    Flakey.models.backend_controller.sync('Person')
    
    deepEqual window.memcache, mem_copy, "Sync restored Memcache"
    
    local_copy = localStorage['flakey-Person']
    localStorage['flakey-Person'] = ""
    
    deepEqual localStorage['flakey-Person'], "", "LocalStorage is blank"
    notDeepEqual local_copy, localStorage['flakey-Person'], "LocalStorage not equal to local_copy"
    
    Flakey.models.backend_controller.sync('Person')
    
    deepEqual local_copy, localStorage['flakey-Person'], "Sync restored LocalStorage"
    
    local = {Person: Flakey.JSON.parse(localStorage['flakey-Person'])}
    deepEqual window.memcache, local, "LocalStorage and window.memcache are equal"
    
    
  # ========================================================================================
  # Util Tests
  # ========================================================================================
  module "Util Functions"
  
  test "Test Deep Compare", () ->
    local = {Person: Flakey.JSON.parse(localStorage['flakey-Person'])}
    deepEqual window.memcache, local, "LocalStorage and window.memcache are equal"
    ok Flakey.util.deep_compare(local, window.memcache), "Deep Compare works for equal objects"
    ok !Flakey.util.deep_compare({'hello': 'this is equal'}, window.memcache), "Deep Compare works for non-equal objects"
    
  test "Test Event System", () ->
    expect 1
    Flakey.events.register 'test', () ->
      ok true, 'Event system trigger registered event'
      
    Flakey.events.trigger 'test' # Should trigger test
    Flakey.events.trigger 'test_2' # Shouldn't trigger test
    Flakey.events.trigger 'test_2', 'namespace' # Shouldn't trigger test
    
    
    
    
    
    
    
