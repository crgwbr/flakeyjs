fs     = require 'fs'
{exec} = require 'child_process'

appFiles  = [
  'flakey'
  'util'
  'models'
  'controllers'
  'views'
  'exports'
]

task 'build', 'Compile flakey.js from source', ->
  appContents = new Array remaining = appFiles.length
  for file, index in appFiles then do (file, index) ->
    fs.readFile "src/#{file}.coffee", 'utf8', (err, fileContents) ->
      throw err if err
      appContents[index] = fileContents
      process() if --remaining is 0
  process = ->
    header = "# ==========================================\n"
    header += "# Compiled: #{(new Date()).toString()}\n\n"
    header += "# Contents:\n"
    for file, index in appFiles
      header += "#   - src/#{file}.coffee\n"
    header += "# ==========================================\n\n"
    
    file = header + appContents.join('\n\n')
    
    fs.writeFile 'flakey.coffee', file, 'utf8', (err) ->
      throw err if err
      exec 'coffee -c flakey.coffee', (err, stdout, stderr) ->
        console.log 'Done.'
