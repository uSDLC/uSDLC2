# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license

instance_index = 0

module.exports.initialise = (next) ->
  CodeMirror.modeURL = '/ext/codemirror/codemirror/mode/%N/%N.js'
  usdlc.source_editor =
    edit: (element, source) ->
      mode = source.attr('type')
      mode = roaster.environment.mode_map[mode] ? mode
      editor = CodeMirror element.get(0),
        mode: mode
        value: source.text()
      CodeMirror.autoLoadMode(editor, mode)
      editor.id = "codemirror_#{++instance_index}"
      update = -> source.text(editor.getValue())
      editor.on 'change', -> usdlc.save_timer editor.id, update
      editor.on 'blur', -> update(); usdlc.save_page()
      return editor
  next()
