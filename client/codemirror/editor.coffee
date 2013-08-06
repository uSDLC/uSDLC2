# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
dialog_options =
  width:      600
  position:   { my: "right top+60", at: "right-5 top", of: window }
  init: (dlg) -> dlg.append(dlg.content = $('<div/>'))
  # fix_height_to_window: 65

module.exports = (options, next = ->) ->
  steps(
    ->  @on 'error', (error) -> console.log(error); @abort()
    ->  @requires '/client/dialog.coffee'
    ->
      @dlg = @dialog
        name: options.name
        fill: (dlg) ->
          dlg.content.empty()
          dlg.editor = usdlc.source_editor.edit(dlg.content, options.source)
        dialog_options, options
      next null, @dlg
  )
