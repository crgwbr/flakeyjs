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

lint_files = [
  'flakey.js'
]


task 'build', 'Compile flakey.js from source', ->
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



task 'lint', 'Run Google\' style checker on source files', ->
  # Check if lint exists
  exec "which gjslint", (error, stdout, stderr) ->
    if error
      console.error "Please install closure linter:"
      console.error "http://code.google.com/closure/utilities/docs/linter_howto.html"
      return

    files = lint_files

    handleFile = ->
      return if files.length == 0
      file = files.shift()
      exec "gjslint #{file}", (error, stdout, stderr) ->
        if error
          console.error stderr
          console.error stdout
          console.error "#{files.length} files left to lint"
          return

        if stdout != ''
          console.log stdout

        # Recurse
        handleFile()

    # Kick off first file
    handleFile()
    


task 'fixlint', 'Run automatic lint fixer on all source files', ->
  # Check if lint exists
  exec "which fixjsstyle", (error, stdout, stderr) ->
    if error
      console.error "Please install closure linter:"
      console.error "http://code.google.com/closure/utilities/docs/linter_howto.html"
      return

    files = lint_files

    console.log "Fixing lint in #{files.length} files"
    handleFile = ->
      return if files.length == 0
      file = files.shift()
      exec "fixjsstyle #{file}", (error, stdout, stderr) ->
        if error
          console.error stderr if stderr != ''
          console.error stdout if stdout != ''
          console.error "#{files.length} files left to fix"
          return

        console.log stdout if stdout != ''

        if files.length
          console.log "#{files.length} files remaining"
          # Recurse
          handleFile()

    # Kick off first file
    handleFile()
  
  
  
# Compile full version of code
closureCompile = (callback) ->
  # Standard options for ornery compilation
  args = "--js flakey.js
          --js_output_file flakey.min.js
          --compilation_level=WHITESPACE_ONLY
          --warning_level=VERBOSE
          --summary_detail_level=3
          --language_in ECMASCRIPT5_STRICT
          "

  exec "java -jar 'tools/closure/compiler.jar' #{args}", { maxBuffer: 1000 * 1024 }, (error, stdout, stderr) ->
    if error
      console.error stderr
      throw error

    # Output compilation message and return
    console.log stdout + stderr
    callback()
      
