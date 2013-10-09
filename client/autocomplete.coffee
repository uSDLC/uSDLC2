# Copyright (C) 2013 paul@marrington.net, see GPL for license
queue = steps.queue

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

module.exports = (opts, next) -> queue ->
  select = (item) -> next(item)
  @requires  '/client/dialog.coffee'
  @dialog
    title: opts.title
    name: opts.title
    init: (dlg) =>
      dlg.append(dlg.input = $('<input>'))
      dlg.input.catcomplete
        source:     opts.source
        autoFocus:  true
        delay:      0
        minLength:  0
        select:     (event, ui) =>
          dlg.dialog 'close'
          select(ui.item)
        response:   (event, ui) =>
          if not ui.content.length
            val = dlg.input.val()
            ui.content.push label: val, value: val
    fill: (dlg) =>
      dlg.input.catcomplete 'option', 'source', opts.source
      set_val = (source) ->
        dlg.input.val source[0]
        dlg.input.catcomplete 'search', ''
        setTimeout (-> dlg.input.focus().select()), 200
      if opts.source instanceof Function
        opts.source (->), (source) -> set_val(source)
      else
        set_val(opts.source)
    dialog_opts, (@dlg) ->
    opts.dialog ? {}