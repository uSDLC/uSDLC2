# Copyright (C) 2013 paul@marrington.net, see /GPL for license

# load ckeditor plugins
roaster.ckeditor.toolbar(
  'ckeditor', 'uSDLC', 'projects', 'documents', 'sections',
  'gwt', 'gwt_coffee', 'source_editor', 'play', 'terminal', 'windows'
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
    next()

usdlc.richCombo = (options) ->
  options = _.clone(options)
  CKEDITOR.plugins.add( options.name,
    requires: 'richcombo'
    init: (editor) ->
      build_list = (next) ->
        options.items (items) =>
          # remove old if pre-built
          contents = $(@_.panel?._.iframe.$).contents()
          contents.find('ul').remove()
          @_.items = {}
          @_.list?._.items = {}
          # load items (again)
          for item in items
            [name,html,tooltip] = item.split('|')
            html ?= name
            name = name.replace(/_/g, ' ')
            @add(name, html, tooltip)
          if not options.no_create
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
          @_.panel.showBlock = (args...) =>
            build_list.call @, =>
              showBlock.apply @_.panel, args if @_.panel
        onClick: (value) ->
          editor.focus()
          options.select(value)
        onRender: ->
          selectionChange = (ev) ->
            @setValue options.selected()
          editor.on 'selectionChange', selectionChange, @
        onOpen: ->
          panel = $('.cke_combopanel')
          if usdlc.lastListClass
            panel.removeClass(usdlc.lastListClass)
          usdlc.lastListClass = options.className
          if options.className
            panel.addClass(options.className)
      )
  )
