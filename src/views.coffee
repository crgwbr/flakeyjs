# * * * * *
# ## Basic wrapper around Eco templates

class Template
  constructor: (eco, name) ->
    @eco = eco
    @name = name
    
  # Render this template with the given context object, return the resulting string
  render: (context = {}) ->
    return @eco(context)

# Call this to load a Flakey.Template object from a compiled eco template.
get_template = (name, tobj) ->
  template = tobj.ecoTemplates[name]
  return new Template(template, name)

Flakey.templates = {
  get_template
  Template: Template
}