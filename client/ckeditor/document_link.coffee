# Copyright (C) 2013 paul@marrington.net, see GPL for license

module.exports = (exchange) ->
  exchange.respond.client ->
    tree_options =
      title:      'Documents...'
      position:   { my: "eft", at: "left+200", of: window }
      closeOnEscape: true
      form: '#tree_docs'
      tree_action: ->
        # TODO: select and add link from action
    doc_url = '/server/http/files.coffee?type=docs'
  
    add_link = (editor, title) ->
      link = editor.document.createElement('a')
      link.setHtml(title)
      link.setAttribute('href', title.replace(/\W/g, '_'))
      editor.insertHtml(link.getOuterHtml())
      
    order = roaster.ckeditor.tools.document_link
    CKEDITOR.plugins.add 'document_link',
      icons: 'document_link',
      init: (editor) ->
        editor.addCommand 'document_link', exec: =>
          title = editor.getSelection()?.getSelectedText()
          if not title?.length
            queue ->
              @requires '/client/tree.coffee', @next ->
              @tree tree_options, (error, dialog) ->
          else
            add_link(editor, title)
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
