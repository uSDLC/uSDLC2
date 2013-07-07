# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
path = require 'path'
window.usdlc = {}

roaster.message = (msg) -> console.log msg

steps(
  ->  @package "jquery,jqueryui,ckeditor"
  ->  @requires "/client/ckeditor/ckeditor.coffee"
  ->  # Go to page specified or return to the last page and location
      if window.location.search is '?edit'
        localStorage.url = "#{window.location.pathname}##{window.location.hash}"
      $('div#base_filler').height($(window).height() - 64)
      usdlc.sources = -> $('textarea[source]', usdlc.document)
      usdlc.edit_page localStorage.url, ->

      actor = null
      usdlc.save_timer = ->
        clearTimeout(actor) if actor
        roaster.message ""
        actor = setTimeout(usdlc.save_page, 2000)
      usdlc.page_editor.on 'key', usdlc.save_timer
      usdlc.page_editor.on 'blur', usdlc.save_page
)

usdlc.load_ace = (next) ->
  usdlc.load_ace = (next) -> next() # only called once
  steps(
    ->  @package "coffee-script,ace"
    ->  @requires "/client/ace/ace.coffee"
    ->  next()
  )

localStorage.url ?= '/uSDLC2/Index'
localStorage.project ?= 'uSDLC2'

clean_html = -> return usdlc.page_editor.getData()

usdlc.save_page = ->
  original = localStorage.page_html
  changed =  clean_html()
  roaster.message ''
  return unless changed isnt original
  save_url = "/server/http/save.coffee?name=#{localStorage.url}"
  steps(
    ->  @requires '/common/patch.coffee'
    ->  @patch.create localStorage.url, original, changed, @next (@changes) ->
    ->  # send it to the server
        xhr = $.post save_url, @changes, @next (data, status, xhr) ->
        xhr.fail -> roaster.message "<b>Save failed</b>"; @abort()
    ->  # all done - clean up
        localStorage.page_html = changed
        roaster.message 'Saved'
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
    localStorage.project = page[1..].split('/')[0].split('#')[0]

  localStorage.url = localStorage["#{localStorage.project}_url"] = page
  [pathname,hash] = page.split('#')
  hash = "##{hash}" if hash
  steps(
    ->  @data pathname
    ->  # parse html into dom
        html = localStorage.page_html = @[localStorage.document = @key]
        usdlc.page_editor.config.baseHref = "/#{localStorage.project}/"
        usdlc.page_editor.setData html, @next
    ->  # prepare for user interaction
        usdlc.document = $(usdlc.page_editor.document.$.body)
        usdlc.page_editor.resetDirty()
        if hash?.length > 1
          setTimeout (-> usdlc.goto_section(hash[1..])), 500
        $('title').html "#{@key} - uSDLC2"
        usdlc.load_ace ->
        # history.pushState from, '', "#{pathname}?edit#{hash ? ''}"
        next()
  )
  
usdlc.source = (header) ->
  el = header.nextUntil('h1,h2,h3,h4,h5,h6').find('textarea[source]')
  if not el.length
    el = $('<textarea>').attr
      source:   'true'
      type:     'gwt.coffee'
      readonly: 'readonly'
    el.insertAfter(header)
  return el  

# restore the state if the user presses the back button
window.onpopstate = (event) -> usdlc.edit_page(event.state) if event.state
