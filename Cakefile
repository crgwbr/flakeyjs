fs     = require 'fs'
{exec} = require 'child_process'

appFiles  = [
  'lib/diff_match_patch.js'
  'lib/jquery-1.7.1.js'
  'lib/JSON2.js'
  'flakey.coffee'
  'util.coffee'
  'models.coffee'
  'controllers.coffee'
  'views.coffee'
  'exports.coffee'
]

DEFAULT_VERSION = "0.0.1"

option '-v', '--version [STRING]', 'Version number of build'

task 'build', 'Compile flakey.js from source', (options) ->
  version = options.version or DEFAULT_VERSION
  build_flakey(version)

task 'build_package', 'Build a standard NPM package', (options) ->
  version = options.version or DEFAULT_VERSION
  build_npm(version)


# Concat and build Flakey.js from source
build_flakey = (version) ->
  appContents = new Array remaining = appFiles.length
  for file, index in appFiles then do (file, index) ->
    fs.readFile "src/#{file}", 'utf8', (err, fileContents) ->
      throw err if err
      if file.indexOf(".coffee") == -1
        appContents[index] = "`#{fileContents}`"
      else
        appContents[index] = fileContents
      process() if --remaining is 0
      
  process = ->
    header = "# ==========================================\n"
    header += "# Version: #{ version }\n"
    header += "# Compiled: #{(new Date()).toString()}\n\n"
    header += "# Contents:\n"
    for file, index in appFiles
      header += "#   - src/#{file}\n"
    header += "# ==========================================\n\n"
    
    file = header + appContents.join('\n\n')
    
    fs.writeFile 'flakey.coffee', file, 'utf8', (err) ->
      throw err if err
      exec 'coffee -c flakey.coffee', (err, stdout, stderr) ->
        throw err if err
        console.log stdout + stderr
        closureCompile () ->
          console.log "Done compiling flakey.js & flakey.min.js"
          
          
# Build an NPM package in the npm-package directory
build_npm = (version) ->  
  JSON = require('json2ify')
  
  exec 'rm -rf npm-package; mkdir npm-package; cp flakey.js npm-package/flakey.js', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr
    
    package = {
      "name": "flakey",
      "description": "Flakey.js MVC Framework for browsers",
      "version": version,
      "repository": {
        "type": "git",
        "url": "git@github.com:crgwbr/flakeyjs.git"
      },
      "author": "Craig Weber <crgwbr@gmail.com>",
      "engines": {
        "node": "*"
      },
      "main": "./flakey.js"
    }
    
    package_file = JSON.stringify(package)
    
    fs.writeFile 'npm-package/package.json', package_file, 'utf8', (err) ->
      throw err if err
      console.log "Done. Compiled npm-package at version #{ version }."
          
          
# Compile full version of code
closureCompile = (callback) ->
  # Standard options for ornery compilation
  args = "--js flakey.js
          --js_output_file flakey.min.js
          --compilation_level=WHITESPACE_ONLY
          --warning_level=VERBOSE
          --summary_detail_level=3
          --language_in ECMASCRIPT5_STRICT"

  exec "java -jar 'tools/closure/compiler.jar' #{args}", { maxBuffer: 1000 * 1024 }, (error, stdout, stderr) ->
    if error
      console.error stderr
      throw error

    # Output compilation message and return
    console.log stdout + stderr
    callback()
  
  
  
  
  