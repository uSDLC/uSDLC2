# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
container = $('<p>').attr('contenteditable', false).css
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
aces = []; containers = {}; hidden = false; in_undo = false; scroll_top = 0

module.exports.initialise = (next) ->
  usdlc.page_editor.on 'beforeCommandExec', (event) ->
    return if event.data.name isnt 'undo' and event.data.name isnt 'redo'
    in_undo = true; scroll_top = $(window).scrollTop()
    usdlc.ace.hide()
  usdlc.page_editor.on 'afterCommandExec', (event) ->
    return if event.data.name isnt 'undo' and event.data.name isnt 'redo'
    in_undo = false; $(window).scrollTop(scroll_top)
    usdlc.ace.show()
  usdlc.page_editor.on 'beforeUndoImage', -> 
    usdlc.ace.hide() unless in_undo
  usdlc.page_editor.on 'afterUndoImage', -> 
    usdlc.ace.show() unless in_undo
  
  usdlc.ace =
    hide: (msg) ->
      return if hidden
      hidden = true
      for id in aces
        $("pre##{id}").show()
        containers[id] = $("p.#{id}").detach()
    show: (msg) ->
      return unless hidden
      hidden = false
      for id in aces
        containers[id].insertAfter(pre = $("pre##{id}"))
        pre.hide()
    edit_all: ->
      usdlc.sources().attr('contenteditable', false).each (index) ->
        usdlc.ace.edit @
    edit: (what) ->
        pre = $(what).hide()
        if not (id = pre.attr('id'))?.length
          pre.attr 'id', id = "gwt_coffee_#{usdlc.sources().length}"
        container = container.clone().insertAfter(pre).text(pre.text())
        editor = ace.edit(container.get(0))
        container.addClass(id)
        aces.push id
        usdlc.ace.config editor, pre.attr 'type'
        ace.require('ace/ext/settings_menu').init(editor)
        usdlc.ace.resize(editor, container)
        editor.on 'change', ->
          pre.text(editor.getValue())
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
