# Copyright (C) 2013 paul@marrington.net, see GPL for license

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
  title:      'File...'
  position:   { my: "top", at: "top", of: window }
  closeOnEscape: false

module.exports = ->
  project = roaster.environment.projects[usdlc.project]
  path = "/server/http/files.coffee"
  exclude = project.exclude ? ''
  include = project.include ? ''
  selector = "exclude=#{exclude}&include=#{include}"
  args = "project=#{usdlc.project}&type=autocomplete"
  steps(
    ->  @requires "/client/edit_source.coffee"
    ->  @json "#{path}?#{args}&#{selector}"
    ->  @requires '/client/dialog.coffee'
    ->
      @dlg = @dialog
        name: 'File...'
        init: (dlg) =>
          dlg.append(dlg.input = $('<input>'))
          dlg.input.catcomplete
            source:     @files
            autoFocus:  true
            delay:      0
            minLength:  0
            select:     (event, ui) =>
              dlg.dialog 'close'
              usdlc.edit_source ui.item
        fill: (dlg) =>
          dlg.input.catcomplete 'option', 'source', @files
          dlg.input.focus().select()
        dialog_options
  )
