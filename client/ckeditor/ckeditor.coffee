# Copyright (C) 2013 paul@marrington.net, see /GPL for license

# load ckeditor plugins
roaster.ckeditor.toolbar(
  'ckeditor', 'uSDLC', 'projects', 'documents', 'sections',
  'code', 'bridge', 'source_editor', 'play', 'terminal',
  'windows'
)
# Open a full page html editor ready forh current document

usdlc.page_editor = roaster.ckeditor.open 'document',
  resize_dir: 'both'
  resize_minWidth: 300
  removeButtons: 'Save,NewPage'
  magicline_color: 'blue'
  # filebrowserBrowseUrl: '/file_browser.coffee'
  # filebrowserImageBrowseLinkUrl: '/image_browser.coffee'
  # filebrowserImageBrowseUrl: '/image_browser.coffee'
  # filebrowserUploadUrl: '/image_upload.coffee'

module.exports.initialise = (next) ->
  # Do things only available once the editor is up and loaded
  usdlc.page_editor.onInstanceReady.push ->
    usdlc.page_editor.resize(600, $(window).height() - 20)
    usdlc.page_editor.on 'focus', ->
      $('#cke_document').css
        'z-index': roaster.zindex++
        position: 'absolute'
    next()
  steps(
    ->  @requires '/client/ckeditor/metadata.coffee'
    ->  usdlc.page_editor.metadata = @metadata
    ->  @requires '/client/ckeditor/rich_combo.coffee'
    ->  usdlc.richCombo = @rich_combo
  )