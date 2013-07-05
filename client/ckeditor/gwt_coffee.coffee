# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
module.exports = (exchange) ->
  exchange.respond.client ->
    dialog_options =
      width:    600
      position: { my: "right bottom", at: "right bottom", of: window }
      init:     (dlg) -> dlg.append(dlg.content = $('<div/>'))
      fix_height_to_window: 100

    CKEDITOR.plugins.add 'gwt_coffee',
      icons: 'gwt_coffee',
      init: (editor) ->
        editor.addCommand 'gwt_coffee', exec: (editor) ->
          section_path = usdlc.section_path()
          # fill dialog with an accordion - one for each ace source on path
          fill = (dlg) ->
            # remove previous contents
            editor.destroy() for editor in dlg.editors if dlg.editors
            # add new content now
            dlg.editors = []
            for section, index in section_path
              source = usdlc.source(section.element)
              dlg.content.append($("<h#{section.level}>").
                html(section.title)).append(panel = $("<div>"))
                panel.data('source', source)
            instantiate = (panel) ->
              if not editor = panel.data('editor')
                editor = usdlc.ace.edit(panel, panel.data('source'))
                dlg.editors.push editor
                panel.data('editor', editor)
              editor.focus()
            dlg.content.accordion
              active:       -1
              heightStyle:  'fill'
              activate:     (event, ui) -> instantiate ui.newPanel
              create:       (event, ui) -> instantiate ui.panel
              
          steps(
            ->  # any error should be shown in red
                @on 'error', (error) -> console.log(error); @abort()
            ->  @requires 'querystring', '/client/dialog.coffee'
            ->  # now we have querystring and window, use them
                dlg = usdlc.instrument_window = @dialog
                  name:   "Instrumentation"
                  title:  "Instrumentation"
                  fill:   fill
                  dialog_options
          )
        editor.ui.addButton 'gwt_coffee',
          label: 'Coffeescript GWT Instrumentation'
          command: 'gwt_coffee'
          toolbar: 'uSDLC'
