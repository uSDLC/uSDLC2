# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
module.exports = (exchange) ->
  exchange.respond.client ->
    order = roaster.ckeditor.tools.windows
    
    usdlc.richCombo
      name: 'windows'
      label: 'Windows'
      toolbar: "uSDLC,#{order[0]}"
      items: (next) ->
        dlgs = roaster.dialogs
        next ("#{key}|#{dlg.dialog('option', 'title')}" for key, dlg of dlgs)
      selected: ->
      select: (value) ->
        if value is 'create'
          alert("Under Construction")
        else
          dlg = roaster.dialogs[value.replace(/\s/g, '_')]
          dlg.dialog 'open'
          dlg.dialog 'moveToTop'
