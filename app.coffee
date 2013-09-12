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
        usdlc.url =
        "#{window.location.pathname}#{window.location.hash}"
      else
        usdlc.url = localStorage.url
      $('div#base_filler').height($(window).height() - 64)
      usdlc.sources = ->
        $('textarea[source]', usdlc.document)
      usdlc.raw_edit_page usdlc.url

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

usdlc.projectStorage = (key, values...) ->
  key = "#{usdlc.project}_#{key}"
  localStorage[key] = values[0] if values.length
  return localStorage[key]
  
usdlc.listStorage = (key, values) ->
  if not values
    return localStorage[key].split('///') if localStorage[key]
    return []
  dict = {}; list = []
  for value in values
    list.push(value) if not dict[value]
    dict[value] = true
  localStorage[key] = list.join('///')
  return list

usdlc.setProject = (project) ->
  usdlc.project = localStorage.project = project
  history.replaceState null, null, "#{project}?edit"

clean_html = -> return usdlc.page_editor.getData()

usdlc.save = (file_name, original_id, changed, next) ->
  next ?= ->
  roaster.message ''
  original = sessionStorage[original_id]
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
      sessionStorage[original_id] = changed
      roaster.message 'Saved'
      next()
  )

save_lockout = 1
usdlc.save_page = ->
  return if save_lockout
  usdlc.raw_save_page(->)
  
usdlc.raw_save_page = (next) ->
  save_lockout++
  for id, save_action of save_actions
    delete save_actions[id]
    save_action()
  changed = clean_html()
  url = usdlc.url.split(/[#\?]/)[0]+".html"
  usdlc.save url, 'page_html', changed, ->
    save_lockout--; next()

usdlc.edit_page = (page, next = ->) ->
  save_lockout++
  usdlc.raw_save_page -> usdlc.raw_edit_page(page, next)
  
usdlc.raw_edit_page = (page, next = ->) ->
  # keep a copy of location information for back button
  from = "#{window.location.pathname}?"+
         "edit##{window.location.hash}"
  # make page address is absolute
  if page[0] isnt '/'
    # adjust relative page by adding the current project
    page = "/#{usdlc.project}/#{page}"
  else
    # or update project name if it has (possibly) changed
    parts = page[1..].split('/')
    usdlc.setProject parts[0].split('#')[0]
    if parts.length < 2
      page = usdlc.projectStorage('url')
      page ?= "#{usdlc.project}/Index"

  localStorage.url = usdlc.url = page
  usdlc.projectStorage 'url', page
  [pathname,hash] = page.split('#')
  hash = "##{hash}" if hash
  sep = if pathname.indexOf('?') is -1 then '?' else '&'
  url = "#{pathname}#{sep}seed=#{usdlc.seed++}"

  load_document = ->
    @on 'error', (err) ->
      roaster.message "<b>New Document</b>"
      @[@key] = ''
    @data pathname

  insert_into_dom = ->
    @on 'error', (err) -> throw err
    usdlc.projectStorage 'document', @key
    html = sessionStorage.page_html = @[@key] ? new_document
    usdlc.page_editor.config.baseHref = "/#{usdlc.project}/"
    usdlc.page_editor.setData html, @next

  prepare_editing = ->
    usdlc.document = $(usdlc.page_editor.document.$.body)
    usdlc.page_editor.resetDirty()
    if hash?.length > 1
      setTimeout (-> usdlc.goto_section(hash[1..])), 500
    project = usdlc.project.replace(/_/g, ' ')
    $('title').html "#{@key} - #{project}"
    usdlc.load_source_editor @next

  release_Lockout_and_continue = ->
    save_lockout = 0
    next()

  steps(
    load_document
    insert_into_dom
    prepare_editing
    release_Lockout_and_continue
  )

new_document = """<html><head>
<link href='document.css' rel='stylesheet' type='text/css'>
</head><body></body></html>"""

usdlc.source = (header) ->
  return usdlc.section_element header, 'textarea[source]', ->
    return $('<textarea>').attr
      source:   'true'
      type:     'gwt.coffee'
      readonly: 'readonly'

# restore the state if the user presses the back button
window.onpopstate = (event) ->
  return if not usdlc.page_editor
  usdlc.edit_page(event.state) if event.state
