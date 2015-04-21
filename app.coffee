# Copyright (C) 2013 paul@marrington.net, see GPL for license
path = require 'path'
window.usdlc = {originals:{}}
usdlc.seed = (new Date()).getTime()

roaster.message = (msg) -> console.log msg
save_actions = {}

roaster.ready ->
  roaster.packages "jquery", "jqueryui", "ckeditor", ->
    roaster.clients "/client/ckeditor/ckeditor.coffee", ->
      roaster.request.css "/app.less"
      # Go to page  or return to the last location
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
      user = (localStorage.user_name ?= 'guest')
      usdlc.set_default_message = (msg) ->
        msg = " <i>#{localStorage.user_name}</i>" if not msg
        roaster.default_message = msg
        roaster.message ''
      usdlc.set_default_message()

      actor = null
      usdlc.save_timer = (id, save_action) ->
        clearTimeout(actor) if actor
        roaster.message ""
        save_actions[id] = save_action if id
        actor = setTimeout(usdlc.save_page, 1000)
      usdlc.page_editor.on 'change', -> usdlc.save_timer()
      usdlc.page_editor.on 'blur', usdlc.save_page
      roaster.ckeditor.show_tab 'uSDLC'

load_source_editor = (next) ->
  pb = $('#progressbar')
  pb.progressbar value: false
  load_source_editor = (next) -> next()
  roaster.packages "coffee-script","codemirror",
  "jquery_terminal", ->
    roaster.clients "/client/codemirror/codemirror.coffee",
    "/client/codemirror/editor.coffee", ->
      $('#loading').text('')
      pb.progressbar('destroy')
      pb.hide()
      require '/client/faye.coffee', (faye) -> faye (faye) ->
        usdlc.faye = faye.subscribe '/usdlc2', (data) ->
          console.log data
  next()

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

lockouts = {}
usdlc.save = (file_name, original_id, changed, next = ->) ->
  return next() if lockouts[file_name]
  lockouts[file_name] = 1
  done = -> lockouts[file_name] = 0; next()
  roaster.message ''
  original = usdlc.originals[original_id]
  return done() unless changed isnt original
  save_url = "/server/http/save.coffee?name=#{file_name}"
  roaster.clients '/common/patch.coffee', (patch) ->
    patch.create file_name, original, changed, (changes) ->
      xhr = $.post save_url, changes, (data, status, xhr) ->
        usdlc.originals[original_id] = changed
        roaster.message 'Saved'
        done()
      xhr.fail =>
        roaster.message "<b>Save failed</b>"
        if confirm('Save failed\n'+
        'Do you want to merge the changes?')
          roaster.message '<b>Merging under construction</b>'
        done()

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
    save_lockout--
    next()

usdlc.edit_page = (page, next = ->) ->
  save_lockout++
  usdlc.raw_save_page -> usdlc.raw_edit_page(page, next)
  
usdlc.raw_edit_page = (page, next = ->) ->
  # keep a copy of location information for back button
  from = "#{window.location.pathname}?"+
         "edit#{window.location.hash}"
  # make page address is absolute
  if page[0] isnt '/'
    # adjust relative page by adding the current project
    page = "/#{usdlc.project}/#{page}"
  else
    # or update project name if it has (possibly) changed
    parts = page[1..].split('/')
    first = parts[0].split('#')
    usdlc.setProject first[0]
    if parts.length < 2
      page = usdlc.projectStorage('url')?.split('#')[0]
      page ?= "#{usdlc.project}/Index"
      page += '#'+first[1] if first.length > 1

  localStorage.url = usdlc.url = page
  usdlc.projectStorage 'url', page
  [pathname,hash] = page.split('#')
  hash = "##{hash}" if hash
  sep = if pathname.indexOf('?') is -1 then '?' else '&'
  url = "#{pathname}#{sep}seed=#{usdlc.seed++}"
  html = ''
  key = roaster.path.basename(
    pathname.split('?')[0]).split('.')[0]

  load_document = (next) ->
    roaster.request.data url, (err, data) ->
      if err
        roaster.message "<b>New Document</b>"
        data = ''
      html = data
      next()

  insert_into_dom = (next) ->
    usdlc.projectStorage 'document', key
    if html.length
      usdlc.originals.page_html = html
    else
      html = new_document
      usdlc.originals.page_html = ''
    usdlc.page_editor.config.baseHref = "/#{usdlc.project}/"
    usdlc.page_editor.setData html, next

  prepare_editing = (next) ->
    usdlc.document = $(usdlc.page_editor.document.$.body)
    usdlc.page_editor.resetDirty()
    if hash?.length > 1
      setTimeout (-> usdlc.goto_section(hash[1..])), 500
    project = usdlc.project.replace(/_/g, ' ')
    document = key.replace(/_/g, ' ')
    project = project.replace(/_/g, ' ')
    $('title').html "#{document} - #{project}"
    save_lockout = 0
    next()

  load_document -> insert_into_dom -> prepare_editing ->
    load_source_editor -> next()

dialog_left = 700
dialog_top = -20
roaster.dialog_position = ->
  w = $(window)
  dialog_left += 80
  dialog_left = 680 if dialog_left > w.width() - 600
  dialog_top += 40
  dialog_top = 0 if dialog_top > w.height() / 2
  my: "left top"
  at: "left+#{dialog_left} top+#{dialog_top}"
  of: window

new_document = """<html><head>
<link href='usdlc.css' rel='stylesheet' type='text/css'>
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
