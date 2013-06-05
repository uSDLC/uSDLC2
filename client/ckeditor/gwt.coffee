# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
module.exports = (exchange) ->
  exchange.respond.client ->
    CKEDITOR.plugins.add 'gwt',
      icons: 'gwt',
      init: (editor) ->
        editor.addCommand 'gwt', exec: (editor) ->
          CKEDITOR.instances.document.insertHtml(
            "<textarea type='gwt'>Given \nWhen \nThen </textarea>")
          usdlc.resize_textareas()
        editor.ui.addButton 'gwt',
          label: 'Given / When / Then ...'
          command: 'gwt'
          toolbar: 'uSDLC'
