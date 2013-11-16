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

module.exports = (opts) -> queue ->
  @requires  '/client/dialog.coffee', @next -> @dialog
    title: opts.title
    name: opts.title
    init: (dlg) =>
      dlg.append(dlg.input = $('<input>'))
      module.exports.widget.init dlg.input, opts, (ev, ui) ->
        dlg.dialog 'close'
        opts.select(ui.item)
    fill: (dlg) => module.exports.widget.fill(dlg.input, opts)
    dialog_opts, (@dlg) ->
    opts.dialog ? {}
    
module.exports.widget =
  init: (input, opts, select) ->
    input.catcomplete
      source:     opts.source
      autoFocus:  true
      delay:      0
      minLength:  0
      select:     select
      response:   (event, ui) =>
        if not ui.content.length
          val = input.val()
          ui.content.push label: val, value: val
  fill: (input, opts) ->
    input.catcomplete 'option', 'source', opts.source
    set_val = (source) ->
      input.val source[0]
      input.catcomplete 'search', ''
      setTimeout (-> input.focus().select()), 200
    if opts.source instanceof Function
      opts.source (->), (source) -> set_val(source)
    else
      set_val(opts.source)
