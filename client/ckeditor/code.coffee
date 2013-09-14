# Copyright (C) 2013 paul@marrington.net, see /GPL for license

module.exports = (exchange) ->
  exchange.respond.client ->
    # any editor not mentioned here will go to the code editor
    usdlc.type_editors =
      gwt: (wrapper) ->
      txt: (wrapper) ->
      
    html_to_code = (html) ->
      return html.
        replace(/<br\/?>/g, '\n').
        replace(/&nbsp;/g, ' ').
        replace(/&lt;/g, '<').
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
        position:
          my: "right top+80", at: "right-5 top", of: window
        init:   (dlg) -> dlg.append(dlg.content = $('<div/>'))
        fix_height_to_window: 105
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
        @on 'error', (error) ->
          console.log(error,error.stack); @abort()
        @requires 'querystring', '/client/dialog.coffee', ->
          # now we have querystring and window, use them
          section = usdlc.section_for(wrapper.$).text()
          dlg = usdlc.bridge_dlg = @dialog
            name:   section
            title:  section
            fill:   fill
            dialog_options
            
    ref = null
    steps(
      ->  @requires '/client/ckeditor/metadata.coffee'
      ->  ref = @metadata.define name: 'Ref', type: 'Links'
    )
    insert = (type) ->
      switch (type)
        when 'gwt'
          CKEDITOR.instances.document.insertHtml(
            "<pre type='gwt'><b>"+
            "Given</b> \n<b>When</b> \n<b>Then</b> </pre>")
          usdlc.page_editor.metadata.add_bridge_and_play_ref()
        else
          CKEDITOR.instances.document.insertHtml(
            "<pre type='#{type}'></pre>")
            
    list = usdlc.listStorage('code_type')
    list = ['gwt'] if not list.length
    list_update = (value) ->
      list.push value
      list = usdlc.listStorage('code_type', list)
    
    CKEDITOR.plugins.add 'code',
      icons: 'code',
      init: (editor) ->
        editor.addCommand 'code', exec: (editor) -> queue ->
          @requires "/client/autocomplete.coffee", ->
            @autocomplete
              title: 'Type...'
              source: list
              (selected) ->
                list_update(selected.value)
                insert selected.value
        editor.ui.addButton 'code',
          label:    'GWT, Code or Data ...'
          command:  'code'
          toolbar:  'uSDLC,4'
        usdlc.page_editor.addMenuGroup('uSDLC')
        editor.addMenuItem 'code',
          label:    'Given / When / Then (Alt-G)'
          command:  'code'
          group:    'uSDLC'
          order:    1
        editor.contextMenu.addListener (element, selection) ->
          return gwt: CKEDITOR.TRISTATE_OFF
        editor.setKeystroke(CKEDITOR.ALT + 71, 'code')
        editor.on 'selectionChange', (evt) ->
          for n in evt.data.path.elements
            if n.getName() is 'pre' and n.hasAttribute('type')
              if edit = usdlc.type_editors[type]
                edit(n)
              else
                return usdlc.embedded_code_editor(n)