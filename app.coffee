# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
path = require 'path'
window.usdlc = {}

roaster.load "jquery,ckeditor", ->
  # Open a full page html editor ready to load with current document
  usdlc.page_editor = roaster.ckeditor.open 'document'#,
    # filebrowserBrowseUrl: '/file_browser.coffee'
    # filebrowserImageBrowseLinkUrl: '/image_browser.coffee'
    # filebrowserImageBrowseUrl: '/image_browser.coffee'
    # filebrowserUploadUrl: '/image_upload.coffee'

  localStorage.url ?= '/uSDLC2/Index'
  localStorage.project ?= 'uSDLC2'

  usdlc.goto_section = (name) ->

  usdlc.save_page = ->
    if usdlc.page_editor.checkDirty()
      save_url = "/server/http/save.coffee?name=#{localStorage.url}"
      original = localStorage.page_html
      changed = usdlc.page_editor.getData()
      steps(
        ->  @requires '/common/patch.coffee'
        ->  @patch.create localStorage.url, original, changed, @next (@changes) ->
        ->  xhr = $.post save_url, @changes, @next (data, status, xhr) ->
            xhr.fail -> alert "Save failed"
        ->  usdlc.page_editor.resetDirty()

      )

  usdlc.edit_page = (page, next = ->) ->
    # keep a copy of location information for back button
    from = "#{window.location.pathname}?edit##{window.location.hash}"
    # make page address is absolute
    if page[0] isnt '/'
      # adjust relative page by adding the current project
      page = "/#{localStorage.project}/#{page}"
    else
      # or update project name if it has (possibly) changed
      localStorage.project = page[1..].split('/')[0]

    localStorage.url = page
    [pathname,hash] = page.split('#')
    hash = "##{hash}" if hash
    key = path.basename(pathname).split('.')[0]
    steps(
      ->  @data pathname
      ->  localStorage.page_html = @[key]
      ->  usdlc.page_editor.setData @[key], @next
      ->  # we have just loaded, so editor is not really dirty
          usdlc.page_editor.resetDirty()
          usdlc.goto_section(hash)
          $('title').html "#{key} - uSDLC2"
          history.pushState from, '', "#{pathname}?edit#{hash ? ''}"
          next()
    )
  # restore the state if the user presses the back button
  window.onpopstate = (event) -> usdlc.edit_page(event.state) if event.state
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
    # Go to page specified or return to the last page and location
    if window.location.search is '?edit'
      localStorage.url = "#{window.location.pathname}##{window.location.hash}"
    usdlc.edit_page localStorage.url, ->
