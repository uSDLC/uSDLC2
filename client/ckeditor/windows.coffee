# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
module.exports = (exchange) ->
  exchange.respond.client ->
    usdlc.richCombo
      name: 'windows'
      label: 'Windows'
      toolbar: 'uSDLC,7'
      items: (next) ->
        dlgs = roaster.dialogs
        next ("#{key}|#{dlg.dialog('option', 'title')}" for key, dlg of dlgs)
      selected: ->
      select: (value) ->
        if value is 'create'
          alert("Under Construction")
        else
          roaster.dialogs[value].dialog 'moveToTop'