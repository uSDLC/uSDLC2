# Copyright (C) 2013 paul@marrington.net, see /GPL for license

patterns = [
  /^#:\s*(.*)\s*$/, (command) ->
    @div('command', command)
  /^#pause\s*(.*)\s*$/, (prompt) ->
    @pause(prompt)
  /^#ask\s*(.*)\s*$/, (prompt) ->
    @ask(prompt)
  /^#(\d)\s*(.*)\s*$/, (level, heading) ->
    @heading(level, heading)
  /^#\s+(\d\d):(\d\d) seconds total\s*$/, (minutes, seconds) ->
    @timer(minutes, seconds)
  /^# (\w\w\w \w\w\w \d\d 2\d\d\d .*)\s*$/, (date) ->
    @div('date', date)
  /^#!!\s*(.*)\s*$/, (comment) ->
    @output(comment, 'error')
  /^Error:\s+(.*)$/, (comment) ->
    @div('error', comment)
  /^#\s*(.*)\s*$/, (comment) ->
    @div('comment', comment)
  /^ok\s.*# SKIP$/, ->
  /^ok\s+(.*)/, (note) ->
    @result('ok', 'ok', true, note)
  /^not ok\s+(.*)/, (note) ->
    @result('not ok', 'not_ok', false, note)
  /^Failed (\d+)\/(\d+), (\d+) skipped, (\d+)% okay\s*$/,
  (failed, total, skipped, ok) ->
    @summary(failed, total, skipped, ok)
  /^(.+)\s*$/, (line) -> @output(line)
]
_div = document.createElement('DIV')
_button = document.createElement('BUTTON')
_span = document.createElement('SPAN')
_pre = document.createElement('PRE')
header_idx = 1
 
document.onkeydown = (event) ->
  if event.keyCode is 80 # P
    window.location.href =  window.location.href

toggle_hidden = (element, class_name) ->
  if element.className is 'hidden'
    element.className = class_name
  else
    element.className = 'hidden'

buttons = []

class Instrument
  constructor: (@ws) ->
    @viewport = document.getElementById('viewport')
    @container = [@viewport]
    @same_action = false; @last_action = null
    @level = 0; @ok = true
  div: (className, text) ->
    div = _div.cloneNode()
    div.className = className
    div.innerHTML = text
    @container[0].appendChild(div)
    return div
  html: (className, html) ->
    @div(className, '').innerHTML = html
  timer: (min, sec) ->
    div = _div.cloneNode()
    div.className = 'timer'
    div.innerHTML = "<b>#{min}:#{sec}</b> minutes total"
    @viewport.appendChild(div)
  heading: (level, heading) ->
    @remove_buttons()
    @fix_level_one() if level is 1
    @container.shift() while level <= @level--
    @container.unshift @div("heading-#{level}", heading)
    @level = level
  result: (title, className, ok, note) ->
    @remove_buttons()
    @ok and= ok
    div = _div.cloneNode()
    div.className = className
    div.innerHTML = "<b>#{title}</b> #{note ? ''}"
    @container[0].appendChild(div)
    @container[0].className += " border-#{className}"
  summary: (failed, total, skipped, ok) ->
    @fix_level_one()
    div = _div.cloneNode()
    contents = []
    if +failed
      div.className = 'failed'
      contents.push "<b>Failed #{failed} of #{total}</b>"
      @viewport.className = 'border-failed'
    else
      div.className = 'passed'
      contents.push "<b>All Passed</b>"
      @viewport.className = 'border-passed'
    contents.push("#{skipped} skipped") if +skipped
    contents.push("#{ok}% okay")
    div.innerHTML = contents.join(', ')
    @viewport.appendChild(div)
  output: (line, type) ->
    add = (line, to) ->
      container = to
      if type
        container = _span.cloneNode()
        container.setAttribute 'class', type
        to.appendChild(container)
      container.appendChild(document.createTextNode(line))
    if not @same_action
      hid = 'output_header_'+header_idx++
      header = @div('output_header '+hid, '')
      div = @div('hidden', '')
      @pre = _pre.cloneNode()
      div.appendChild @pre
      add line[0..32]+'...', header
      header.onclick = => toggle_hidden(div, hid)
    add line+'\n', @pre
  fix_level_one: ->
    className = if @ok then "ok" else "not_ok"
    level_1 = @container.slice(-2,-1)[0]
    level_1.className += " border-#{className}"
    @ok = true
  find: (statement) ->
    # Look for a matching statement, then return the action
    for pattern, index in patterns by 2
      if matched = pattern.exec(statement)
        # matched = (match.toString() for match in matched)
        parameters = matched[1..] if matched.length > 1
        return [action = patterns[index + 1], parameters]
    return null
  display: (line) ->
    line = line.trim()
    return if not line?.length
    action = @find line
    return false if not action
    @same_action = action[0] is @last_action
    @last_action = action[0]
    try action[0].apply(@, action[1]) catch err
      console.log action.toString()
      console.log err, err.stack if err.stack
    window.scrollTo(0,document.body.scrollHeight)
  interact: (prompt, titles..., action) ->
    div = @div 'prompt', "#{prompt}<br>"
    add_button = (title, polarity) =>
      buttons.push button = _button.cloneNode()
      button.innerHTML = title ? 'Fail'
      button.onclick = =>
        @remove_buttons()
        @ws.send action(polarity)
      div.appendChild button
    add_button titles[0], true
    add_button titles[1], false
  remove_buttons: ->
    b.parentNode.removeChild(b) for b in buttons
    buttons = []
  ask: (prompt) ->
    @interact prompt, "Pass", (ok) ->
      "gwt.test(#{ok}, '#{prompt}');"
  pause: (prompt) ->
    @interact prompt, "OK", (ok) ->
      "if (#{not ok})gwt.fail('#{prompt}');"

window.instrument = ->
  loc = window.location
  ws = new WebSocket "ws://#{loc.hostname}:#{loc.port}"+
    "/server/http/gwt.coffee#{loc.search}"
  ws.onmessage = (event) -> instrument.display(event.data)
  ws.onclose = ->  instrument.display("Connection closed")
  instrument = new Instrument(ws)
  instrument.html('again',
    "<a href='#{window.location.href}'>again</a>")
