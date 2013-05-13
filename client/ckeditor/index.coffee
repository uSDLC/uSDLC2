# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license

# load ckeditor plugins
external = (names...) ->
  for name in names
    CKEDITOR.plugins.addExternal name, '/client/ckeditor/', "#{name}.coffee"
    roaster.ckeditor.default_options.extraPlugins += ",#{name}"
external 'projects', 'documents'
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
      build_list = (next) ->
        options.items (items) =>
          # remove old if pre-built
          $(@_.panel?._.iframe.$).contents().find('ul').remove()
          @_.items = {}
          @_.list?._.items = {}
          # load items (again)
          for item in items.sort()
            name = item.replace(/_/g, ' ')
            @add(name, name, item)
          @add 'create', '<i><b>New...</b></i>', 'New...'
          @_.committed = 0
          @commit()
          next()

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
          @add options.selected()
          showBlock= @_.panel.showBlock
          @_.list.mark = ->
          @_
          @_.panel.showBlock = (args...) =>
            build_list.call @, =>
              showBlock.apply @_.panel, args if @_.panel
        onClick: (value) ->
          editor.focus()
          options.select(value)
        onRender: ->
          selectionChange = (ev) ->
            $('.cke_combo__projects .cke_combo_text').css('width', 'auto')
            @setValue options.selected()
          editor.on 'selectionChange', selectionChange, this
        onOpen: ->
      )
  )
