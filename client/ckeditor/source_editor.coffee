# Copyright (C) 2013 paul@marrington.net, see /GPL for license
module.exports = (exchange) ->
  exchange.respond.client ->
    order = roaster.ckeditor.tools.source_editor
    
    CKEDITOR.plugins.add 'source_editor',
      icons: 'source_editor'
      init: (editor) ->
        editor.addCommand 'source_editor', exec: (editor) ->
          a = $(usdlc.get_caret().$).parentsUntil('.Ref', 'a')
          roaster.clients '/client/tree_filer.coffee', (tree_filer) ->
            if a.length
              eval(a.attr('href'))
            else
              tree_filer()
          return true

        editor.ui.addButton 'source_editor',
          label: 'Source Editor (Alt-V Shift-Click)'
          command: 'source_editor'
          toolbar: "uSDLC,#{order[0]}"
        usdlc.page_editor.addMenuGroup('uSDLC')
        editor.addMenuItem 'source_editor',
          label:    'Source Editor (Alt-V Shift-Click)'
          command:  'source_editor'
          group:    'uSDLC'
          order:    order[1]
        editor.contextMenu.addListener (element, selection) ->
          return source_editor: CKEDITOR.TRISTATE_OFF
        altV = CKEDITOR.ALT + 86
        editor.setKeystroke(altV, 'source_editor')
        editor.on 'contentDom', ->
          editor.editable().on 'click', (event) ->
            return if not (a = $(event.data.$.target)).is('a')
            href = a.attr('href')

            if /^javascript:/.test(href)
              roaster.clients '/client/edit_source.coffee',
              '/client/ckeditor/bridge.coffee', -> eval(href)
            else if /^\w+(\/\w+)?$/.test(href)
              usdlc.edit_page(href)
            else
              window.open(href, '_blank')
            event.preventDefault?()
            event.cancel()