# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
module.exports = (exchange) ->
  exchange.respond.client ->
    ref = null
    steps(
      ->  @requires '/client/ckeditor/metadata.coffee'
      ->  ref = @metadata.define name: 'Ref', type: 'Links'
    )
    CKEDITOR.plugins.add 'gwt',
      icons: 'gwt',
      init: (editor) ->
        editor.addCommand 'gwt', exec: (editor) ->
          CKEDITOR.instances.document.insertHtml(
            "<pre type='gwt'>Given \nWhen \nThen </pre>")
          ref
            name: 'Bridge'
            url: "javascript:usdlc.bridge_editor()"
          ref
            name: 'Play'
            url: "javascript:usdlc.play()"
        editor.ui.addButton 'gwt',
          label:    'Given / When / Then ...'
          command:  'gwt'
          toolbar:  'uSDLC,4'
        usdlc.page_editor.addMenuGroup('uSDLC')
        editor.addMenuItem 'gwt',
          label:    'Given / When / Then (Alt-G)'
          command:  'gwt'
          group:    'uSDLC'
          order:    1
        editor.contextMenu.addListener (element, selection) ->
          return gwt: CKEDITOR.TRISTATE_OFF
        editor.setKeystroke(CKEDITOR.ALT + 71, 'gwt')
