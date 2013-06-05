# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
container = $('<div>').attr('contenteditable', false).css
  position: 'relative'
  top: 0
  right: 0
  bottom: 0
  left: 0
  # height: '200px'
  width: '99%'
  border: '1px solid #eee'
  "z-index": 1000
container_id = 0

window_container = $('<div>').css
  position: 'absolute'
  top: 0
  right: 0
  bottom: 0
  left: 0
  height: 'auto!important'
  width: 'auto!important'
  # overflow: 'hidden'
  "z-index": 10000

window_specs = "height=200,width=400,left=0,top=0,location=no,menubar=no,toolbar=no"

base = usdlc.ace_base
last_tab = null

module.exports.initialise = (next) ->
  usdlc.ace =
    clear: ->
      usdlc.sources().each ->
        textarea = $(@).show()
        textarea.data('ace_editor').destroy()
        textarea.data('ace_container').remove()
    hide: ->
      usdlc.sources().each ->
        $(@).show().data('ace_container').detach()
    show: ->
      usdlc.sources().each ->
        textarea = $(@).hide()
        textarea.data('ace_container').insertAfter(textarea)
    edit_all: ->
      usdlc.sources().attr('contenteditable', false).each (index) ->
        usdlc.ace.edit @
    edit: (what) ->
        textarea = $(what).hide()
        container = container.clone().insertAfter(textarea).text(textarea.text())
        editor = ace.edit(container.get(0))
        textarea.data('ace_editor', editor).data('ace_container', container)
        usdlc.ace.config editor, textarea.attr 'type'
        ace.require('ace/ext/settings_menu').init(editor)
        usdlc.ace.resize(editor, container)
        editor.on 'change', ->
          textarea.text(editor.getValue())
          usdlc.ace.resize(editor, container)
        editor.on 'focus', ->
          usdlc.ace.editor = editor
          last_tab = roaster.ckeditor.show_tab 'Ace'
        editor.on 'blur', ->
          # usdlc.ace.editor = null
          roaster.ckeditor.show_tab last_tab
    config: (editor, type) ->
      editor.setTheme("ace/theme/twilight")
      type = type.split('.').slice(-1)[0]
      editor.getSession().setMode("ace/mode/#{type}")
    resize: (editor, container) ->
      lineHeight = editor.renderer.lineHeight;
      rows = editor.getSession().getLength();
      container.height(rows * lineHeight);
      editor.resize();
    window: (name, content) ->
      w = window.open '', name, window_specs
      w.ace = window.ace
      head = $ w.document.head; body = $ w.document.body
      head.append $ "<title>#{name}</title>"
      head.append styles.ace_editor.clone()
      head.append styles.ace_tm.clone()
      container = window_container.clone().appendTo(body)
      container.html "#{content}"
      editor = w.ace.edit container.get 0
  next()
