# Copyright (C) 2013 paul@marrington.net, see /GPL for license
dialog_options =
  width: 600
  init: (dlg) -> dlg.append(dlg.content = $('<div/>'))

preload = roaster.preload '/client/dialog.coffee'

module.exports = (args...) -> preload (dialog) ->
  module.exports = (options, next = ->) ->
    dialog
      name: options.name
      fill: (dlg) ->
        dlg.content.empty()
        dlg.editor =
          usdlc.source_editor.edit(dlg.content, options.source)
      dialog_options, options, (dlg) ->
        set_focus = -> dlg.editor.focus()
        dlg.click set_focus
        dlg.prev().click set_focus # heading
        next null, dlg
  module.exports(args...)
