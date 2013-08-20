# Copyright (C) 2013 paul@marrington.net, see GPL for license
dirs = require 'dirs'

module.exports = (exchange) ->
  exchange.respond.client ->
    usdlc.play = ->
      doc = usdlc.url.split('#')[0]
      doc = doc.split('/').slice(-1)[0]
      sp = (section.title for section in usdlc.section_path())
      sections = ".*/#{sp.join('/')}([/\\.].*)*$"
      sections = sections.replace(/\s/g, '_')

      onResize = (dlg) ->
        height = usdlc.instrument_window.height() - 10
        usdlc.instrument_window.iframe.height(height)

      steps(
        ->  @on 'error', -> @abort()
        ->  @requires 'querystring', '/client/dialog.coffee'
        ->  # now we have querystring and window, use them
          projects = roaster.environment.projects
          url = "/instrument.html?" + @querystring.stringify
            project:  projects[usdlc.project].base
            document: doc
            sections: sections
          dlg = usdlc.instrument_window = @dialog
            name:   "Instrument"
            title:  "Play: #{section.title}"
            url:    url
            fill:   (dlg) -> dlg.iframe.attr('src', url)
            after:  @next
            resizeStop: (dlg) -> onResize(dlg)
            dialog_options
      )
      
    init = (dlg) ->
      dlg.append(dlg.iframe = $('<iframe/>'))
      dlg.iframe.height(dlg.height() - 10)
    dialog_options =
      width:      600
      position:
        my: "right top+20"
        at: "right top"
        of: window
      fix_height_to_window: 130
      init:       init

    CKEDITOR.plugins.add 'play',
      icons: 'play',
      init: (editor) ->
        editor.addCommand 'play', exec: usdlc.play
        editor.ui.addButton 'play',
          label: 'Play instrumentation in this section'
          command: 'play'
          toolbar: 'uSDLC,7'

        usdlc.page_editor.addMenuGroup('uSDLC')
        editor.addMenuItem 'play',
          label:    'Play Instrumentation (Alt-P)'
          command:  'play'
          group:    'uSDLC'
          order:    4
        editor.contextMenu.addListener (element, selection) ->
          return play: CKEDITOR.TRISTATE_OFF
        editor.setKeystroke(CKEDITOR.ALT + 80, 'play')

    roaster.replay = ->
      return if not usdlc.instrument_window
      usdlc.instrument_window.dialog 'moveToTop'
      iframe = usdlc.instrument_window.iframe
      iframe.attr('src', iframe.attr('src'))
      iframe.focus()
