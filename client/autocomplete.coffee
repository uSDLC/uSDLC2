# Copyright (C) 2013 paul@marrington.net, see GPL for license
$.widget  "custom.catcomplete", $.ui.autocomplete,
  _renderMenu: ( ul, items ) ->
    that = this
    currentCategory = ""
    $.each items, ( index, item ) =>
      cat = item.category
      if cat and (cat isnt currentCategory)
        ul.append "<li class='ui-autocomplete-category'>" +
                  "#{item.category}</li>"
        currentCategory = item.category
      @_renderItemData( ul, item )

dialog_opts =
  width:      'auto'
  autoResize: true
  minHeight:  50
  position:   { my: "top", at: "top", of: window }
  closeOnEscape: true

preload = roaster.preload '/client/dialog.coffee'

module.exports = (opts) -> preload (dialog) ->
  module.exports = (opts) ->
    dialog
      title: opts.title
      name: opts.title
      notes: opts.notes
      init: (dlg) ->
        dlg.append(dlg.input = $('<input>'))
        if opts.notes
          dlg.append(notes = $('<div>'))
          notes.addClass("autocomplete_notes").html(opts.notes)
        module.exports.widget.init dlg.input, opts, (ev, ui) ->
          dlg.dialog 'close'
          usdlc.in_modal = false
          opts.select(ui.item)
      fill: (dlg) ->
        module.exports.widget.fill(dlg.input, opts)
        usdlc.in_modal = true
      dialog_opts, (dlg) ->
      opts.dialog ? {}
  module.exports.widget = widget
  module.exports(opts)
    
module.exports.widget = widget =
  init: (input, opts, select) ->
    input.catcomplete
      source:     opts.source
      autoFocus:  false
      delay:      0
      minLength:  0
      select:     select
      response:   (event, ui) =>
        if true or not ui.content.length
          val = input.val()
          ui.content.push label: val, value: val
  fill: (input, opts) ->
    input.catcomplete 'option', 'source', opts.source
    input.catcomplete 'search', ''
    setTimeout (-> input.focus().select()), 200