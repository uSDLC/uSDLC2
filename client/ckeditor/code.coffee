# Copyright (C) 2013 paul@marrington.net, see /GPL for license

module.exports = (exchange) ->
  exchange.respond.client ->
    # any editor not mentioned here will go to the code editor
    usdlc.type_editors = {}
#       gwt: (wrapper) ->
#         wrapper.attributes.contenteditable = true
#       txt: (wrapper) ->
#         wrapper.attributes.contenteditable = true
      
    html_to_code = (html = '') ->
      return html.
        replace(/<br\/?>/g, '\n').
        replace(/&nbsp;/g, ' ').
        replace(/&lt;/g, '<').
        replace(/&gt;/g, '>').
        replace(/<[^>]+>/g, '')
    code_to_html = (code) ->
      return code
      div = $('<div>')
      CodeMirror.runMode(code, 'coffeescript', div.get(0))
      return div.html()
          
    ref = null
    roaster.clients '/client/ckeditor/metadata.coffee',
    (metadata) ->
      ref = metadata.define name: 'Ref', type: 'Links'
    insert = (type) ->
      template = "/client/templates/#{type}_template.coffee"
      roaster.clients template, (contents) ->
        contents = contents?() ? ''
        CKEDITOR.instances.document.insertHtml(
          "<pre type='#{type}' title='#{type}'>"+
          "#{contents}</pre>")
      usdlc.page_editor.metadata.add_bridge_and_play_ref()
            
    list = usdlc.listStorage('code_type')
    list = ['gwt'] if not list.length
    list_update = (value) ->
      list.push value
      list = usdlc.listStorage('code_type', list)
    
    order = roaster.ckeditor.tools.code
    selection_timer = null
    CKEDITOR.plugins.add 'code',
      requires: 'widget'
      icons: 'code',
      init: (editor) ->
        editor.addCommand 'code', exec: (editor) ->
          roaster.clients "/client/autocomplete.coffee",
          (autocomplete) ->
            autocomplete
              title: 'Type...'
              source: list
              select: (selected) ->
                list_update(selected.value)
                insert selected.value
        editor.ui.addButton 'code',
          label:    'GWT, Code or Data... (Alt-G)'
          command:  'code'
          toolbar:  "uSDLC,#{order[0]}"
        usdlc.page_editor.addMenuGroup('uSDLC')
        editor.addMenuItem 'code',
          label:    'GWT, Code or Data... (Alt-G)'
          command:  'code'
          group:    'uSDLC'
          order:    order[1]
        editor.contextMenu.addListener (element, selection) ->
          return code: CKEDITOR.TRISTATE_OFF
        editor.setKeystroke(CKEDITOR.ALT + 71, 'code')
      
        editor.widgets.add 'code-widget',
          upcast: (el, data) ->
            if el.name isnt 'pre' or not el.attributes.type
              return false
            return true
            div = new CKEDITOR.htmlParser.element 'div',
              type: el.attributes.type
              title: el.attributes.title
            div.setHtml el.getHtml?() ? ''
            return div
          init: ->
            @once 'focus', ->
              el = $(@element.$)
              ed = $('<div>').css
                position:      'absolute'
                width:         el.width()
                height:        el.height()
                top:           '-1000px'
                right:         '-1000px'
              $('body').append(ed)
              el.text html_to_code el.html()
              @setData 'attr', (key) -> el.attr(key)
              fit = =>
                doc = $(editor.document.$)
                doco = $('iframe',$(editor.container.$))
                doco = doco.offset()
                ed.outerWidth el.outerWidth() - 4
                ed.outerHeight el.outerHeight() - 4
                scrollTop = doc.scrollTop()
                scrollLeft = doc.scrollLeft()
                offset = el.offset()
                offset.top += doco.top + 2 - scrollTop
                offset.left += doco.left + 2 - scrollLeft
                ed.css 'z-index': roaster.zindex + 2
                ed.offset offset
              code_editor = usdlc.source_editor.edit ed,
                attr: (key) => @data.attr(key)
                text: (value) =>
                  if value then el.text(value); return fit()
                  return el.text()
              code_editor.setOption 'lineNumbers', false
              code_editor.setOption 'gutters', []
              doc = $(editor.document.$)
              blur = =>
                return if not @editing
                ed.hide()
                @editing = false
              doc.scroll blur
              editor.on 'change', blur
              editor.on 'beforeCommandExec', blur
              editor.on 'contentDomInvalidated', blur
              editor.on 'dialogShow', blur
              editor.on 'resize', blur
              do edit = =>
                return if @editing
                @editing = true
                ed.show()
                usdlc.current_section = @element.$
                fit()
                code_editor.focus()
              @on 'focus', edit
              @wrapper.on 'click', edit
              @on 'blur', blur