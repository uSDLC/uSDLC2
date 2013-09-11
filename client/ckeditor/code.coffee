# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
module.exports = (exchange) ->
  exchange.respond.client ->
    ref = null
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
            "<pre type='#{type}'>Given \nWhen \nThen </pre>")
            
    list = usdlc.listStorage('code_type')
    list ?= ['gwt', 'gwt.coffee']
    
    CKEDITOR.plugins.add 'code',
      icons: 'code',
      init: (editor) ->
        editor.addCommand 'code', exec: (editor) ->
          @requires "/client/autocomplete.coffee", ->
            @autocomplete 'Type...', @list, 'gwt', (value) ->
              usdlc.listStorage('code_type', @list..., value)
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
