# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
sources = null
# iframe = $('<iframe>').css
#   position: 'relative'
#   width: '100%'
#   height: '200px'

container = $('<div>').css
  position: 'relative'
  top: 0
  right: 0
  bottom: 0
  left: 0
  height: '200px'
  width: '400px'
  border: '1px solid #eee'
  "z-index": 10000
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

module.exports.initialise = (next) ->
  doc = usdlc.page_editor.document.$
  win = doc.defaultView ? doc.parentWindow
  body = usdlc.document()
  html = usdlc.document().parent()
  head = html.find('head')
  head.append $('head style[id=ace_editor]').detach()
  head.append $('head style[id=ace-tm]').detach()
  win.ace = window.ace

  sources = {}

  usdlc.ace =
    clear: ->
      sources.each (el) ->
        $(el).data('ace_editor').destroy().data('ace_container').remove().show()
    hide: ->
      sources.each (el) ->
        $(el).data('ace_container').detach().show()
    show: ->
      sources.each (el) ->
        $(el).hide().data('ace_container').insertAfter(el)
    edit5: ->
    edit7: ->
      html = usdlc.document().parent()
      sources = html.find('pre[type]')#.css visibility: 'hidden'
      sources.attr('contenteditable', false).first().each (index) ->
        pre = $(@)
        container = container.clone()
        $('body').append container
        container.text(pre.text())
        editor = ace.edit(container.get(0))
        editor.setTheme("ace/theme/twilight");
        editor.getSession().setMode("ace/mode/coffee")
        # editor.on 'change', pre pre.text(editor.getValue())
    edit: ->
      sources = usdlc.document().find('pre[type]').hide()
      sources.attr('contenteditable', false).each (index) ->
        pre = $(@)
        container = container.clone().insertAfter(pre).text(pre.text())
        editor = ace.edit(container.get(0))
        editor.setTheme("ace/theme/twilight");
        editor.getSession().setMode("ace/mode/coffee")
        editor.on 'change', -> el.text(editor.getValue())
        editor.on 'focus', ->
        editor.on 'blur', ->
    edit6: ->
      he = head.get(0)
      insert = (src) ->
        script = document.createElement('script')
        script.setAttribute('src', src)
        he.appendChild script
      insert "/!client,library/#{usdlc.ace_base}/ace.js"
      insert "/!client,library/client/ace/window.coffee"
    edit4: ->
      html = usdlc.document().parent()
      doc = html.get(0).parentNode
      win = doc.defaultView ? doc.parentWindow
      head = html.find('head')
      head.append styles.ace_editor.clone()
      head.append styles.ace_tm.clone()
      win.aces = []
      sources = html.find('pre[type]')
      sources.attr('contenteditable', false).css visibility: 'hidden'
      sources.each (index) ->
        el = $(@)
        if iframe?
          iframer = iframe.clone().insertAfter(el)
          iframer.attr('contenteditable', false)
          head = iframer.contents().find('body')
          head.append styles.ace_editor.clone()
          head.append styles.ace_tm.clone()
          body = iframer.contents().find('body')
          body.append container = container.clone()
        else
          container = container.clone().insertAfter(el)
          container.attr('contenteditable', false)
        container.attr('id', id = "ace_container_#{container_id}")
        container.data('ace_source_element', el)
        el.data('ace_container', container)
        container.text(el.text())
        # This runs in the ckeditor iframe, hence the shenannigans
        kickstarter = (id) ->
          container = document.getElementById(id)
          el = container.data('ace_source_element')
          aces[id] = editor = ace.edit(container)
          editor.setTheme("ace/theme/twilight");
          editor.getSession().setMode("ace/mode/coffee")
          editor.on 'change', -> el.text(editor.getValue())

          editor.on 'focus', -> #usdlc.ace.window 'name',el.text()
        script = doc.createElement("script")
        script.innerText = "(#{kickstarter.toString()})('#{id}')"
        head.append $(script)

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
