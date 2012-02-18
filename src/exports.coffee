# * * * * *
# ## CommonJS exports

# Make this available via CommonJS'
if module?
  module.exports = Flakey

# Assign it to the window object, if we're in a browser and a window exists.
if window
  window.Flakey = Flakey