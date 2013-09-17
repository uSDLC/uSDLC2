# Copyright (C) 2013 paul@marrington.net, see GPL for license

module.exports = (exchange) ->
  exchange.respond.client ->
    add_link = (editor) ->
      link = editor.document.createElement('a')
      title = editor.getSelection().getSelectedText()
      link.setHtml(title)
      link.setAttribute('href', title.replace(/\W/g, '_'))
      editor.insertHtml(link.getOuterHtml())
      
    order = roaster.ckeditor.tools.document_link
    CKEDITOR.plugins.add 'document_link',
      icons: 'document_link',
      init: (editor) ->
        editor.addCommand 'document_link',
          exec: -> add_link(editor)
        editor.ui.addButton 'document_link',
          label: 'Link highlight to document (Alt-L)'
          command: 'document_link'
          toolbar: "uSDLC,#{order[0]}"
        usdlc.page_editor.addMenuGroup('uSDLC')
        editor.addMenuItem 'document_link',
          label:    'Link Document (Alt-L)'
          command:  'document_link'
          group:    'uSDLC'
          order:    order[1]
        editor.contextMenu.addListener (element, sel) ->
          return document_link: CKEDITOR.TRISTATE_OFF
        editor.setKeystroke(CKEDITOR.ALT + 76, 'document_link')
