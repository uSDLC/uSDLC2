# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
module.exports = (exchange) ->
  exchange.respond.client ->
    CKEDITOR.plugins.add "ace_configuration",
      icons: 'ace_configuration',
      init: (editor) ->
        editor.addCommand 'ace_configuration', exec: (editor) ->
          if usdlc.ace.editor
            usdlc.ace.editor.showSettingsMenu()
        editor.ui.addButton 'ace_configuration',
          label: 'Ace Configuration',
          command: 'ace_configuration',
          toolbar: 'Ace'
