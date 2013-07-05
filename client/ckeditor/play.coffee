# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
dirs = require 'dirs'

module.exports = (exchange) ->
  exchange.respond.client ->
    dialog_options =
      width:            600
      position:         { my: "right top+60", at: "right top", of: window }
      init:             (dlg) -> dlg.append(dlg.iframe = $('<iframe/>'))

    CKEDITOR.plugins.add 'play',
      icons: 'play',
      init: (editor) ->
        editor.addCommand 'play', exec: (editor) ->
          doc = localStorage.url.split('#')[0].split('/').slice(-1)[0]
          sp = (section.title for section in usdlc.section_path())
          sections = ".*/#{sp.join('/')}([/\\.].*)*$".replace(/\s/g, '_')
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
                  title:  "Instrument '#{section.title}'"
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

