# Copyright (C) 2013 paul@marrington.net, see /GPL for license

module.exports = (exchange) ->
  exchange.respond.client ->
    queue = steps.queue; ref = null
    steps(
      ->  @requires '/client/ckeditor/metadata.coffee'
      ->  ref = @metadata.define name: 'Ref', type: 'Links'
    )
    insert = (type) ->
      switch (type)
        when 'gwt'
          CKEDITOR.instances.document.insertHtml(
            "<pre type='gwt'>Given \nWhen \nThen </pre>")
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
