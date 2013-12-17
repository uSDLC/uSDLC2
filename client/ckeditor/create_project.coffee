# Copyright (C) 2013 paul@marrington.net, see GPL for license
preload = roaster.preload '/client/dialog.coffee'

module.exports = (exchange) -> preload (dialog) ->
  module.exports = (exchange) ->
    form = $('#add_project')
    base_path_field = form.find('.project_path')
    name_field = form.find('.project_name')
    opts = source: ->
    dialog
      name: 'Add Project'
      init: (dlg) =>
        add_project = ->
          form = $('#add_project')
          base_path = base_path_field.val()
          name = name_field.val()
          if window.confirm("Add uSDLC for project '"+
          name+"' on path '"+base_path+"'?")
            roaster.request.json "/client/ckeditor/projects.coffee?add="+
            name+"&path="+base_path, ->
              usdlc.setProject name.replace(/\s/g, '_')
              usdlc.edit_page 'Index'
              dlg.dialog 'close'
        dlg.append form
        name_field.change ->
          if not base_path_field.val()
            base_path_field.val(
              name_field.val().replace /\s+/, '_')
          add_project()
        base_path_field.change add_project
      fill: (dlg) =>
        base_path_field.val ''
        name_field.val ''
      width:      'auto'
      autoResize: true
      minHeight:  50
      title:      'Add Project...'
      position:
        my: "top center"
        at: "top center"
        of: window
      closeOnEscape: true
  module.exports(exchange)
