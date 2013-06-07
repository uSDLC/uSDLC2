# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
module.exports = (exchange) ->
  exchange.respond.client ->
    CKEDITOR.plugins.add 'play',
      icons: 'play',
      init: (editor) ->
        editor.addCommand 'play', exec: (editor) ->
          caret = usdlc.page_editor.getSelection().getRanges()[0].startContainer
          for parent in caret.getParents(true)
            break if parent.getAttribute?('id') is 'document'
            owner = parent
          start = $(owner.$)
          if not start.is('h1,h2,h3,h4,h5,h6')
            start = start.prevAll('h1,h2,h3,h4,h5,h6').first()
        editor.ui.addButton 'play',
          label: 'Play instrumentation in this section'
          command: 'play'
          toolbar: 'uSDLC'
