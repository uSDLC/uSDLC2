# Copyright (C) 2013 paul@marrington.net, see GPL for license
module.exports = (exchange) ->
  exchange.respond.client ->
    usdlc.user = ->
      users = localStorage.users ?= []
      source = [localStorage.user_name ? 'guest']
      form = $('#user_management')
      name_fld = form.find('input.user_name')
      email_fld = form.find('input.email')
      
      roaster.client "/client/dialog.coffee", (doalog) ->
        dialog
          name: 'User Management'
          init: (dlg) ->
            dlg.append form
            name_fld.change ->
              localStorage.user_name = name_fld.val()
              usdlc.set_default_message()
            email_fld.change ->
              localStorage.user_email = email_fld.val()
          fill: (dlg) ->
            name_fld.val localStorage.user_name ? ''
            email_fld.val localStorage.user_email ? ''
          width:      'auto'
          autoResize: true
          minHeight:  50
          title:      'User Management...'
          position:
            my: "center top",
            at: "center top", of: window
          closeOnEscape: true
          
    CKEDITOR.plugins.add 'user',
      icons: 'user',
      init: (editor) ->
        editor.addCommand 'user', exec: usdlc.user
        order = roaster.ckeditor.tools.pairing
        editor.ui.addButton 'user',
          label:    'User (alt-U)'
          command:  'user'
          toolbar:  "uSDLC,#{order[0]}"
        editor.setKeystroke(CKEDITOR.ALT + 85, 'user')
