# Copyright (C) 2013 paul@marrington.net, see GPL for license
queue = steps.queue

$.widget  "custom.catcomplete", $.ui.autocomplete,
  _renderMenu: ( ul, items ) ->
    that = this
    currentCategory = ""
    $.each items, ( index, item ) =>
      if item.category isnt currentCategory
        ul.append "<li class='ui-autocomplete-category'>" +
                  "#{item.category}</li>"
        currentCategory = item.category
      @_renderItemData( ul, item )

dialog_options =
  width:      'auto'
  autoResize: true
  minHeight:  50
  position:   { my: "top", at: "top", of: window }
  closeOnEscape: false

module.exports = (title, choices, value, next) -> queue ->
  @requires  '/client/dialog.coffee', ->
    @dlg = @dialog
      title: title
      name: title
      init: (dlg) =>
        dlg.append(dlg.input = $('<input>'))
        dlg.input.val value if value
        dlg.input.catcomplete
          source:     choices
          autoFocus:  true
          delay:      0
          minLength:  0
          select:     (event, ui) =>
            dlg.dialog 'close'
            next ui.item
      fill: (dlg) =>
        dlg.input.catcomplete 'option', 'source', choices
        dlg.input.focus().select()
      dialog_options