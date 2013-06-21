# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
path = require 'path'
window.usdlc = {}

roaster.message = (msg) -> console.log msg

steps(
  ->  @package "jquery,ckeditor"
  ->  @requires "/client/ckeditor/ckeditor.coffee"
  ->  # Go to page specified or return to the last page and location
      if window.location.search is '?edit'
        localStorage.url = "#{window.location.pathname}##{window.location.hash}"
      usdlc.document = $('div#document')
      $('div#base_filler').height($(window).height() - 64)
      usdlc.sources = -> $('textarea[source]')
      usdlc.base = $('head base')
      usdlc.edit_page localStorage.url, ->

      actor = null; dirty = false
      save_page = ->
        dirty = false;
        usdlc.save_page()
      user_action = ->
        clearTimeout(actor) if actor
        if not dirty and dirty = usdlc.page_editor.checkDirty()
          roaster.message ""
        actor = setTimeout(save_page, 2000)
      $(document.body).keyup(user_action).click(user_action)
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

clean_html = ->
  changed = usdlc.document.clone()
  changed.find('.ace_editor').remove()
  changed.find('[type]').removeAttr('style')
  changed.find('textarea[source]').removeAttr('contenteditable')
  changed = changed.html().replace /&\w+?;/g, (match) ->
    switch match
      when '&gt;' then return '>'
      when '&lt;' then return '<'
      when '&amp;' then return '&'
      else return match

usdlc.save_page = ->
  original = localStorage.page_html
  changed = clean_html()
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
  usdlc.base.attr 'href', "/#{localStorage.project}/"
  steps(
    ->  @data pathname
    ->  # parse html into dom
        localStorage.page_html = @[localStorage.document = @key]
        usdlc.document.html @[@key]
        last_tag = usdlc.document.children().last().prop('tagName')
        usdlc.document.append('<br>') if last_tag isnt 'BR'
        load_ace @next  # so we can set source edit fields
    ->  # we have just loaded, so editor is not really dirty
        usdlc.ace.edit_all()
        usdlc.page_editor.resetDirty()
        if hash?.length > 1
          setTimeout ( -> usdlc.goto_section(hash[1..])), 500
        $('title').html "#{@key} - uSDLC2"
        history.pushState from, '', "#{pathname}?edit#{hash ? ''}"
        usdlc.document.blur()
        next()
  )

# restore the state if the user presses the back button
window.onpopstate = (event) -> usdlc.edit_page(event.state) if event.state
