# Copyright (C) 2013 paul@marrington.net, see GPL for license
module.exports = (exchange) ->
  exchange.respond.client ->
    # Code for editor that pops up for bridge code
    usdlc.bridge_editor = ->
      usdlc.page_editor.metadata.add_bridge_and_play_ref()
      dialog_options =
        width:  600
        init:   (dlg) -> dlg.append(dlg.content = $('<div/>'))
        closeOnEscape: false
  
      section_path = usdlc.section_path()
      # fill dialog for each source on path
      fill = (dlg) ->
        # remove previous contents
        if dlg.editors
          dlg.content.accordion('destroy')
          dlg.content.empty()
        # add new content now
        dlg.editors = []
        for section, index in section_path
          source = usdlc.source(section.element)
          dlg.content.append($("<h#{section.level}>").
            html(section.title)).append(panel = $("<div>"))
            panel.data('source', source)
        instantiate = (panel) ->
          if not editor = panel.data('editor')
            editor = usdlc.source_editor.edit(
              panel, panel.data('source'))
            dlg.editors.push editor
            panel.data('editor', editor)
          editor.focus()
        dlg.content.accordion
          active:       -1
          heightStyle:  'fill'
          activate:     (event, ui) ->
            instantiate ui.newPanel
          create:       (event, ui) ->
            instantiate ui.panel
        dlg.dialog 'option', 'title',
          "Edit: #{section.title}"

      onResize = (dlg) ->
        usdlc.bridge_dlg.content.accordion('refresh')

      roaster.clients '/client/dialog.coffee', (dialog) ->
        dialog
          name:   "Instrumentation"
          title:  "Bridge"
          fill:   fill
          resizeStop: (dlg) -> onResize(dlg)
          dialog_options
          (dlg) -> usdlc.bridge_dlg = dlg
            
    order = roaster.ckeditor.tools.bridge
    CKEDITOR.plugins.add 'bridge',
      icons: 'bridge',
      init: (editor) ->
        editor.addCommand 'bridge',
          exec: usdlc.bridge_editor
        editor.ui.addButton 'bridge',
          label: 'GWT Bridge Code (Alt-D)'
          command: 'bridge'
          toolbar: "uSDLC,#{order[0]}"
        usdlc.page_editor.addMenuGroup('uSDLC')
        editor.addMenuItem 'bridge',
          label:    'GWT Bridge Code (Alt-D)'
          command:  'bridge'
          group:    'uSDLC'
          order:    order[1]
        editor.contextMenu.addListener (element, selection) ->
          return bridge: CKEDITOR.TRISTATE_OFF
        editor.setKeystroke(CKEDITOR.ALT + 68, 'bridge')
