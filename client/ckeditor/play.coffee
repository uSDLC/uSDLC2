# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
dirs = require 'dirs'

module.exports = (exchange) ->
  exchange.respond.client ->
    dialog_options =
      closable:         false
      maximizable:      true
      minimizable:      true
      collapsable:      true
      minimizeLocation: 'right'
      dblclick:         'maximize'
      icons:            {collapse: "ui-icon-close"}
      width:            600
      position:         { my: "right top+60", at: "right top", of: window }
      init:             (dlg) -> dlg.append(dlg.iframe = $('<iframe/>'))
      maximize:         (evt, dlg) -> console.log("MAXIMIZE")
      collapse:         (evt, dlg) -> usdlc.instrument_window.dialog('close')

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
          level = +start.prop("tagName")[1] ? 1
          path = [section = start.text()]
          start.prevAll('h1,h2,h3,h4,h5,h6').each ->
            parent = $(this)
            if (parent_level = +parent.prop("tagName")[1]) < level
              level = parent_level
              return path.unshift parent.text()
            else
              return false  # found root
          doc = localStorage.url.split('#')[0].split('/').slice(-1)[0]
          sections = ".*/#{path.join('/')}([/\\.].*)*$".replace(/\s/g, '_')
          steps(
            ->  # any error should be shown in red
                @on 'error', -> @abort()
            ->  @requires 'querystring', '/client/dialog.coffee'
            ->  # now we have querystring and window, use them
                url = "/instrument.html?" + @querystring.stringify
                  project:  roaster.environment.projects[localStorage.project]
                  document: doc
                  sections: sections
                dlg = usdlc.instrument_window = @dialog
                  name:   "Instrument"
                  title:  "Instrument '#{section}'"
                  url:    url
                  fill:   (dlg) -> dlg.iframe.attr('src', url)
                  after:  @next
                  dialog_options
                dlg.resize_to_fit = ->
                  dlg.iframe.height(
                    dlg.iframe.get(0).contentWindow.document.body.scrollHeight)
          )
        editor.ui.addButton 'play',
          label: 'Play instrumentation in this section'
          command: 'play'
          toolbar: 'uSDLC'
