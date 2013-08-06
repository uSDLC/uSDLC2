# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
ref = null

usdlc.edit_source = (item) -> # item.value item.path item.category
  item.key = item.path.replace /[\.\/]/g, '_'
  # add a unique seed so that response is not cached by the browser
  url = "/server/http/read.coffee?filename=#{item.path}&seed=#{usdlc.seed++}"
  steps(
    ->  @requires '/client/codemirror/editor.coffee'
    ->  @data url
    ->
      parts = item.value.split('.')
      attr = -> parts[parts.length - 1]
      text = (value) =>
        if value
          usdlc.save item.path, item.key, value
        else
          return localStorage[item.key] = @read

      @editor
        name:     item.key
        title:    "#{item.value} - #{item.category}"
        fix_height_to_window: 20
        source:   { attr, text }
        position:
          my: "right top+10", at: "right-10 top", of: window

      item_data = "{value:'#{item.value}'," +
        "path:'#{item.path}',category:'#{item.category}'}"
      path = "javascript:usdlc.edit_source(#{item_data})"
      ref name: item.value, url: path
  )

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
  project = roaster.environment.projects[localStorage.project]
  path = "/server/http/files.coffee"
  exclude = project.exclude ? ''
  include = project.include ? ''
  selector = "exclude=#{exclude}&include=#{include}"
  args = "project=#{localStorage.project}&type=autocomplete"
  steps(
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
module.exports.initialise = (next) ->
  steps(
    ->  @requires '/client/ckeditor/metadata.coffee'
    ->  ref = @metadata.define name: 'Ref', type: 'Links'
    ->  next()
  )