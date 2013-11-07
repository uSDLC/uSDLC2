# Copyright (C) 2013 paul@marrington.net, see GPL for license

add_project = (base_path, name) ->

module.exports = (exchange) -> queue ->
  form = $('#add_project')
  base_path_field = form.find('.project_path')
  name_field = form.find('.project_name')
  opts = source: ->
  @requires "/client/dialog.coffee", @next -> @dialog
    name: 'Add Project'
    init: (dlg) ->
      dlg.append form
      @autocomplete.widget.init base_path_field, opts,
      (ev, ui) ->
      base_path_field.change ->
        name = base_path_field.val()
        # massage to a real name
    fill: (dlg) ->
      base_path_field.val ''
      name_field.val ''
      @autocomplete.widget.fill base_path_field, opts
    width:      'auto'
    autoResize: true
    minHeight:  50
    title:      'Add Project...'
    position:
      my: "top center"
      at: "top center"
      of: window
    closeOnEscape: true
