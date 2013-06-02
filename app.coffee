# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
path = require 'path'
window.usdlc = {}

steps(
  ->  @package "jquery,ckeditor"
  ->  @requires "/client/ckeditor/ckeditor.coffee"
  ->  # Go to page specified or return to the last page and location
      if window.location.search is '?edit'
        localStorage.url = "#{window.location.pathname}##{window.location.hash}"
      usdlc.document = $('div#document')
      usdlc.sources = -> $('textarea[source]')
      usdlc.base = $('head base')
      usdlc.edit_page localStorage.url, ->
)

load_ace = (next) ->
  load_ace = (next) -> next() # only called once
  steps(
    ->  @package "coffee-script,ace"
    ->  @requires "/client/ace/ace.coffee"
    ->  next()
  )

localStorage.url ?= '/uSDLC2/Index'
localStorage.project ?= 'uSDLC2'

usdlc.save_page = ->
  if usdlc.page_editor.checkDirty()
    save_url = "/server/http/save.coffee?name=#{localStorage.url}"
    original = localStorage.page_html
    changed = usdlc.page_editor.getData()
    usdlc.sources().removeAttr('contenteditable')
    usdlc.ace.hide()
    steps(
      ->  @requires '/common/patch.coffee'
      ->  @patch.create localStorage.url, original, changed, @next (@changes) ->
      ->  xhr = $.post save_url, @changes, @next (data, status, xhr) ->
          xhr.fail -> alert "Save failed"
      ->  usdlc.page_editor.resetDirty()
    )
    usdlc.ace.show()

usdlc.edit_page = (page, next = ->) ->
  usdlc.ace?.clear()
  # keep a copy of location information for back button
  from = "#{window.location.pathname}?edit##{window.location.hash}"
  # make page address is absolute
  if page[0] isnt '/'
    # adjust relative page by adding the current project
    page = "/#{localStorage.project}/#{page}"
  else
    # or update project name if it has (possibly) changed
    localStorage.project = page[1..].split('/')[0].split('#')[0]

  localStorage.url = localStorage["#{localStorage.project}_url"] = page
  [pathname,hash] = page.split('#')
  hash = "##{hash}" if hash
  usdlc.base.attr 'href', "/#{localStorage.project}/"
  steps(
    ->  @data pathname
    ->  localStorage.page_html = @[localStorage.document = @key]
    ->  usdlc.document.html @[@key]
    ->  load_ace @next  # so we can set source edit fields
    ->  # we have just loaded, so editor is not really dirty
        usdlc.ace.edit()
        usdlc.page_editor.resetDirty()
        if hash?.length > 1
          setTimeout ( -> usdlc.goto_section(hash[1..])), 500
        $('title').html "#{@key} - uSDLC2"
        history.pushState from, '', "#{pathname}?edit#{hash ? ''}"
        # resize textareas
        $('textarea').each usdlc.resize_textarea
        usdlc.document.blur()
        next()
  )

  usdlc.resize_textarea = (index, textarea) ->
    textarea = $(textarea)
    lines = textarea.text().split(/\s*\r?\n/)
    cols = Math.max((line.length for line in lines)...)
    rows = lines.length
    textarea.attr('cols', cols)
    textarea.attr('rows', rows)

# restore the state if the user presses the back button
window.onpopstate = (event) -> usdlc.edit_page(event.state) if event.state
