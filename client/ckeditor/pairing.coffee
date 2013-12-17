# Copyright (C) 2013 paul@marrington.net, see GPL for license
module.exports = (exchange) ->
  exchange.respond.client ->
    roaster.clients "/client/dialog.coffee",
    "/client/autocomplete.coffee",
    (dialog, autocomplete) ->
      pair_name_field = opts = null
      opts = source: localStorage.pairs ? []
      usdlc.pairing = ->
        form = $('#pairing')
        dialog
          name: 'Pairing'
          init: (dlg) ->
            dlg.append form
            form.find('div.pairing').buttonset()
            pair_name_field = $('#pair_name')
            $('#create_pairing').click ->
              create_pairing()
              pair_name_field.hide()
            $('#close_pairing').click ->
              close_pairing()
              pair_name_field.hide()
            $('#join_pairing').click ->
              pair_name_field.show()
              join_pairing pair_name_field.val()
            autocomplete.widget.init pair_name_field,
            opts, (ev, ui) ->
              join_pairing ui.item
            pair_name_field.change ->
              join_pairing pair_name_field.val()
              if not (usdlc.pair_master in pairs)
                opts.source.push usdlc.pair_master
                opts.source.sort()
                localStorage.pairs = opts.source
          fill: (dlg) ->
            pair_name_field.val usdlc.pair_master ? ''
            @autocomplete.widget.fill pair_name_field, opts
          width:      'auto'
          autoResize: true
          minHeight:  50
          title:      'User Management...'
          position:
            my: "top center"
            at: "top center"
            of: window
          closeOnEscape: true

    CKEDITOR.plugins.add 'pairing',
      icons: 'pairing',
      init: (editor) ->
        editor.addCommand 'pairing', exec: usdlc.pairing
        order = roaster.ckeditor.tools.pairing
        editor.ui.addButton 'pairing',
          label:    'Pairing (alt-P)'
          command:  'pairing'
          toolbar:  "uSDLC,#{order[0]}"
        editor.setKeystroke(CKEDITOR.ALT + 80, 'pairing')
        
    pairing_message = (control, list) ->
      items = [' ']
      for item in list
        if item is control
          item = "<i>#{item}</i>"
        items.push item
      usdlc.set_default_message items.join(' ')
      
    close_pairing = ->
      usdlc.set_default_message()
      usdlc.is_master = false
      usdlc.pair_master = null
      
    create_pairing = ->
      close_pairing()
      usdlc.is_master = true

    join_pairing = (master) ->
      return if not master?.length
      return if master is usdlc.pair_master
      close_pairing()
      usdlc.pair_master = master
      pairing_message(usdlc.pair_master,
        [usdlc.pair_master, localStorage.user_name])
