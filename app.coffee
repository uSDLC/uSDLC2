# Copyright (C) 2013 paul@marrington.net, see GPL for license
path = require 'path'
window.usdlc = {}
usdlc.seed = (new Date()).getTime()

roaster.message = (msg) -> console.log msg

save_actions = {}

roaster.ready ->
  steps(
    ->  @package "jquery,jqueryui,ckeditor"
    ->  @requires "/client/ckeditor/ckeditor.coffee",
                  "/app.less"
    ->  # Go to page  or return to the last location
      loc = window.location
      if loc.search is '?edit' and loc.pathname.length > 2
        localStorage.url =
        "#{window.location.pathname}#{window.location.hash}"
      $('div#base_filler').height($(window).height() - 64)
      usdlc.sources = ->
        $('textarea[source]', usdlc.document)
      usdlc.edit_page localStorage.url

      actor = null
      usdlc.save_timer = (id, save_action) ->
        clearTimeout(actor) if actor
        roaster.message ""
        save_actions[id] = save_action if id
        actor = setTimeout(usdlc.save_page, 2000)
      usdlc.page_editor.on 'key', -> usdlc.save_timer()
      usdlc.page_editor.on 'blur', usdlc.save_page
      roaster.ckeditor.show_tab 'uSDLC'
  )

usdlc.load_source_editor = (next) ->
  # only called once
  usdlc.load_source_editor = (next) -> next()
  steps(
    ->  @package "coffee-script,codemirror,jquery_terminal"
    ->  @requires "/client/codemirror/codemirror.coffee"
    ->  @requires "/client/codemirror/editor.coffee"
    ->  next()
  )

localStorage.url ?= '/uSDLC2/Index'
localStorage.project ?= 'uSDLC2'

clean_html = -> return usdlc.page_editor.getData()

usdlc.save = (file_name, original_id, changed, next) ->
  next ?= ->
  roaster.message ''
  original = localStorage[original_id]
  return next() unless changed isnt original
  save_url = "/server/http/save.coffee?name=#{file_name}"
  steps(
    ->  @requires '/common/patch.coffee'
    ->  @patch.create file_name, original, changed,
           @next (@changes) ->
    ->  # send it to the server
      xhr = $.post save_url, @changes,
        @next (data, status, xhr) ->
      xhr.fail =>
        roaster.message "<b>Save failed</b>"; @abort next
    ->
      localStorage[original_id] = changed
      roaster.message 'Saved'
      next()
  )

usdlc.save_page = ->
  for id, save_action of save_actions
    delete save_actions[id]
    save_action()
  changed =  clean_html()
  url = "#{localStorage.url.split(/[#\?]/)[0]}.html"
  usdlc.save url, 'page_html', changed

usdlc.edit_page = (page, next = ->) ->
  # keep a copy of location information for back button
  from = "#{window.location.pathname}?"+
         "edit##{window.location.hash}"
  # make page address is absolute
  if page[0] isnt '/'
    # adjust relative page by adding the current project
    page = "/#{localStorage.project}/#{page}"
  else
    # or update project name if it has (possibly) changed
    localStorage.project =
      page[1..].split('/')[0].split('#')[0]

  localStorage.url =
    localStorage["#{localStorage.project}_url"] = page
  [pathname,hash] = page.split('#')
  hash = "##{hash}" if hash
  sep = if pathname.indexOf('?') is -1 then '?' else '&'
  url = "#{pathname}#{sep}seed=#{usdlc.seed++}"
  steps(
    ->  @data pathname
    ->  # parse html into dom
      html = localStorage.page_html =
        @[localStorage.document = @key]
      usdlc.page_editor.config.baseHref =
        "/#{localStorage.project}/"
      usdlc.page_editor.setData html, @next
    ->  # prepare for user interaction
      usdlc.document = $(usdlc.page_editor.document.$.body)
      usdlc.page_editor.resetDirty()
      if hash?.length > 1
        setTimeout (-> usdlc.goto_section(hash[1..])), 500
      $('title').html "#{@key} - uSDLC2"
      history.pushState from, '',
        "#{pathname}?edit#{hash ? ''}"
      usdlc.load_source_editor next
  )

usdlc.source = (header) ->
  return usdlc.section_element 'textarea[source]', ->
    return $('<textarea>').attr
      source:   'true'
      type:     'gwt.coffee'
      readonly: 'readonly'

# restore the state if the user presses the back button
window.onpopstate = (event) ->
  return if not usdlc.page_editor
  usdlc.edit_page(event.state) if event.state
