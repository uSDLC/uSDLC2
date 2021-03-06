# Copyright (C) 2013 paul@marrington.net, see /GPL for license

# define plugs and order for button bar and context menu
roaster.ckeditor.tools =
  projects: [1]
  documents: [2]
  sections: [3]
  windows: [4]
  document_link: [5, 1]
  code: [6, 2]
  bridge: [7, 3]
  source_editor: [8, 4]
  play: [9, 5]
  terminal: [10]
  user: [11]
  pairing: [12]
# load ckeditor plugins
roaster.ckeditor.toolbar('ckeditor', 'uSDLC'
  (key for key, value of roaster.ckeditor.tools)...)
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
    fto = null
    restore_focus = ->
      return if usdlc.in_modal
      clearTimeout fto
      fto = setTimeout (-> usdlc.in_focus.focus()), 200
    w = $(window)
    w.click (event) ->
      clearTimeout fto
      if document.activeElement is document.body
        restore_focus()
    usdlc.page_editor.on 'focus', (e) ->
      usdlc.in_focus = usdlc.page_editor
      if document.activeElement is document.body
        restore_focus()
      $('#cke_document').css
        'z-index': roaster.zindex++
        position: 'absolute'
      return true
    setTimeout (->
      usdlc.page_editor.document.$.body.onkeydown =
      window.onkeydown), 300
    next()
  roaster.clients '/client/ckeditor/metadata.coffee',
  '/client/ckeditor/rich_combo.coffee', (md, rc) ->
    usdlc.page_editor.metadata = md
    usdlc.richCombo = rc
