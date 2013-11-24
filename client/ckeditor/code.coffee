# Copyright (C) 2013 paul@marrington.net, see /GPL for license

module.exports = (exchange) ->
  exchange.respond.client ->
    # any editor not mentioned here will go to the code editor
    usdlc.type_editors =
      gwt: (wrapper) ->
        n.removeAttribute('contenteditable')
      txt: (wrapper) ->
        n.removeAttribute('contenteditable')
      
    html_to_code = (html) ->
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
    # Code for editor that pops up for bridge code
    usdlc.embedded_code_editor = (wrapper) ->
      dialog_options =
        width:  600
        init:   (dlg) -> dlg.append(dlg.content = $('<div/>'))
        closeOnEscape: false
  
      # fill dialog with source
      fill = (dlg) ->
        dlg.content.empty()
        src =
          attr: (key) -> wrapper.getAttribute(key)
          text: (value) ->
            if value
              wrapper.setHtml(code_to_html(value))
            else
              return html_to_code(wrapper.getHtml())
        edit = usdlc.source_editor.edit
        dlg.editor = edit(dlg.content, src)
        dlg.editor.focus()

      queue ->
        section = usdlc.section_for(wrapper.$).text()
        @requires 'querystring', '/client/dialog.coffee',
        @next -> @dialog
          name:   section
          title:  section
          fill:   fill
          dialog_options
    ref = null
    steps(
      ->  @requires '/client/ckeditor/metadata.coffee'
      ->  ref = @metadata.define name: 'Ref', type: 'Links'
    )
    insert = (type) -> queue ->
      template = "/client/templates/#{type}_template.coffee"
      @requires template, @next (contents) ->
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
      icons: 'code',
      init: (editor) ->
        editor.addCommand 'code', exec: (editor) -> queue ->
          @requires "/client/autocomplete.coffee", @next ->
            @autocomplete
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
        editor.on 'selectionChange', (evt) ->
          clearTimeout selection_timer
          for n in evt.data.path.elements
            if n.getName() is 'pre' and n.hasAttribute('type')
              return selection_timer = setTimeout ( ->
                type = n.getAttribute('type')
                n.setAttribute('contenteditable', 'false')
                edit = usdlc.type_editors[type] ?
                  usdlc.embedded_code_editor
                return edit(n)
              ), 200
