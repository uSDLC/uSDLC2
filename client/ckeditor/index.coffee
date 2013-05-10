# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license

# load ckeditor plugins
CKEDITOR.plugins.addExternal 'projects', '/client/ckeditor/', 'projects.coffee'
# CKEDITOR.addExternal 'sections', '/client/ckeditor/sections.coffee'
roaster.ckeditor.default_options.extraPlugins += ',projects'
roaster.ckeditor.default_options.toolbarGroups.push name: 'usdlc'
roaster.ckeditor.default_options.toolbarViews.uSDLC = 'usdlc'
# Open a full page html editor ready to load with current document
usdlc.page_editor = roaster.ckeditor.open 'document'#,
  # filebrowserBrowseUrl: '/file_browser.coffee'
  # filebrowserImageBrowseLinkUrl: '/image_browser.coffee'
  # filebrowserImageBrowseUrl: '/image_browser.coffee'
  # filebrowserUploadUrl: '/image_upload.coffee'

module.exports.ready = (next) ->
  # Do things only available once the editor is up and loaded
  usdlc.page_editor.once 'instanceReady', ->
    # 'New Page' button opens index page on curent project
    usdlc.page_editor.getCommand('newpage').exec = (editor) ->
      usdlc.edit_page 'Index'
      return true
    usdlc.page_editor.getCommand('preview').exec = (editor) ->
      window.open localStorage.url
    usdlc.page_editor.getCommand('save').exec = (editor) ->
      usdlc.save_page()
    usdlc.page_editor.commands.save.enable()
    next()

usdlc.richCombo = (options) ->
  CKEDITOR.plugins.add( options.name,
    requires: 'richcombo'
    init: (editor) ->
      editor.ui.addRichCombo( options.name,
        label: options.label
        title: options.label
        toolbar: options.toolbar
        # allowedContent:
        panel:
          css: [ CKEDITOR.skin.getPath( 'editor' ) ].
                concat(editor.config.contentsCss)
          multiSelect: false
          attributes: 'aria-label': options.label
        init: ->
          @startGroup options.label
          for item in options.items.sort()
            name = item.replace(/_/g, ' ')
            @add(name, name, item)
          @startGroup "Add #{options.label}"
          @add('create', 'New...', 'New...')
        onClick: (value) ->
          editor.focus()
          options.select(value)
        onRender: ->
          selectionChange = (ev) ->
            $('.cke_combo__projects .cke_combo_text').css('width', 'auto')
            @setValue options.selected()
          editor.on 'selectionChange', selectionChange, this
        onOpen: ->
        reset: ->
      )
  )