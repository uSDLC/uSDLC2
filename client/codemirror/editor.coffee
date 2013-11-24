# Copyright (C) 2013 paul@marrington.net, see /GPL for license
dialog_options =
  width: 600
  init: (dlg) -> dlg.append(dlg.content = $('<div/>'))

module.exports = (options, next = ->) -> queue ->
  @on 'error', (error) ->
    console.log(error, error.stack ? '')
    @abort()
  @requires '/client/dialog.coffee', @next -> @dialog
    name: options.name
    fill: (dlg) ->
      dlg.content.empty()
      dlg.editor =
        usdlc.source_editor.edit(dlg.content, options.source)
    dialog_options, options, (dlg) ->
      pos = my: "right top+60", at: "right-5 top", of: window
#       dlg.position pos
      set_focus = -> dlg.editor.focus()
      dlg.click set_focus
      dlg.prev().click set_focus # heading
      next null, dlg
