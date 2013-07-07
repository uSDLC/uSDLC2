# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license

last_tab = null

module.exports.initialise = (next) ->
  usdlc.ace =
    edit: (element, source) ->
      editor = ace.edit(element.get(0))
      usdlc.ace.config editor, source.attr('type')
      editor.setValue(source.text())
      ace.require('ace/ext/settings_menu').init(editor)
      editor.on 'change', ->
        source.text(editor.getValue())
        usdlc.save_timer()
      editor.on 'focus', ->
        usdlc.ace.active = true
        usdlc.ace.editor = editor
        last_tab = roaster.ckeditor.show_tab 'Ace'
      editor.on 'blur', ->
        usdlc.ace.active = false
        usdlc.save_page()
        roaster.ckeditor.show_tab last_tab
      return editor

    config: (editor, type) ->
      editor.setTheme("ace/theme/twilight")
      type = type.split('.').slice(-1)[0]
      editor.getSession().setMode("ace/mode/#{type}")
  next()
