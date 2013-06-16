# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
module.exports = (exchange) ->
  exchange.respond.client ->
    CKEDITOR.plugins.add 'gwt_coffee',
      icons: 'gwt_coffee',
      init: (editor) ->
        editor.addCommand 'gwt_coffee', exec: (editor) ->
          id = "gwt_coffee_#{usdlc.sources().length}"
          CKEDITOR.instances.document.insertHtml(
            "<textarea source='true' type='gwt.coffee' id='#{id}'></pre>")
          usdlc.ace.edit "##{id}"
        editor.ui.addButton 'gwt_coffee',
          label: 'Coffeescript GWT Instrumentation'
          command: 'gwt_coffee'
          toolbar: 'uSDLC'
