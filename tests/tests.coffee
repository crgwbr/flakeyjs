$ = Flakey.$

class Person extends Flakey.models.Model
  @model_name: 'Person', 
  @fields: ['id', 'first_name', 'last_name', 'email_address', 'phone_number']


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
  stop()
  bdfl.save () =>
    start()
  
  john = new Person {
    first_name: 'John'
    last_name: 'Resig'
    phone_number: '(555) 555-5555'
  }
  stop()
  john.save () =>
    start()
  
    
  test "Build initial model", () ->   
    expect 10
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
    return
    
  test "Push a version", () ->
    expect 10
    bdfl.email_address = "test@example.com"
    
    stop()
    bdfl.save () =>
      start()
    
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
    return
    
  test "Test Evolve Model", () ->
    expect 4
    version_id = bdfl.versions[bdfl.versions.length - 2].version_id # Get Pervious version
    previous_bdfl = bdfl.evolve(version_id)
    
    equal previous_bdfl.first_name, 'Guido', 'First Name Matches'
    equal previous_bdfl.last_name, 'van Rossum', 'Last Name Matches'
    equal previous_bdfl.email_address, undefined, 'Email Address not yet set'
    equal previous_bdfl.phone_number, undefined, 'Phone Number not yet set'
    return
    
  test "Test Evolving Model didn't affect original model", () ->
    expect 10
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
    return
    
  test "Test Popping a version", () ->
    expect 10
    bdfl.pop_version()
    
    stop()
    bdfl.save()
    
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
    
    
    
    
    
    
    
    
    
