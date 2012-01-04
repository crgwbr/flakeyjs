# ==========================================
# Flakey.js Views
# Craig Weber
# ==========================================

class Template
  constructor: (eco, name) ->
    @eco = eco
    @name = name
    
  render: (context = {}) ->
    return @eco(context)
    
get_template = (name, tobj) ->
  template = tobj.ecoTemplates[name]
  return new Template(template, name)

Flakey.templates = {
  get_template
  Template: Template
}