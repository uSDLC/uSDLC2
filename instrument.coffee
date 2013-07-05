# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license

patterns = [
  /^#:\s*(.*)\s*$/, (command) -> @div('command', command)
  /^#(\d)\s*(.*)\s*$/, (level, heading) -> @heading(level, heading)
  /^#\s+(\d\d):(\d\d) seconds total\s*$/, (minutes, seconds) -> @timer(minutes, seconds)
  /^# (\w\w\w \w\w\w \d\d 2\d\d\d .*)\s*$/, (date) -> @div('date', date)
  /^#\s*(.*)\s*$/, (comment) -> @div('comment', comment)
  /^ok\s.*# SKIP$/, -> 
  /^ok\s+(.*)/, (note) -> @result('ok', 'ok', true, note)
  /^not ok\s+(.*)/, (note) -> @result('not ok', 'not_ok', false, note)
  /^Failed (\d+)\/(\d+), (\d+) skipped, (\d+)% okay\s*$/, (failed, total, skipped, ok) ->
    @summary(failed, total, skipped, ok)
  /^(.+)\s*$/, (line) -> @output(line)
]
_div = document.createElement('DIV')
_br = document.createElement('BR')

toggle_hidden = (element, class_name) ->
  if element.className is 'hidden'
    element.className = class_name
  else
    element.className = 'hidden'

class Instrument
  constructor: ->
    @container = [@viewport = document.getElementById('viewport')]
    @same_action = false; @last_action = null
    @level = 0; @ok = true
  div: (className, text) ->
    div = _div.cloneNode()
    div.className = className
    div.innerText = text
    @container[0].appendChild(div)
    return div
  html: (className, html) ->
    @div(className, '').innerHTML = html
  timer: (minutes, seconds) ->
    div = _div.cloneNode()
    div.className = 'timer'
    div.innerHTML = "<b>#{minutes}:#{seconds}</b> seconds total"
    @viewport.appendChild(div)
  heading: (level, heading) ->
    @fix_level_one() if level is 1
    if level > @level
      @container.unshift(@div("heading-#{level}", heading))
    else
      @container.shift()
      @container.shift() if level < @level
      @container.unshift(@div("heading-#{level}", heading))
    @level = level
  result: (title, className, ok, note) ->
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
  output: (line) ->
    return if not @level
    if @same_action
      @last_div.appendChild(document.createTextNode(line))
      @last_div.appendChild(_br.cloneNode())
    else
      header = @div('output_header', '')
      @last_div = @div('hidden', '')
      header.innerHTML = "#{line}<b>...</b>"
      header.onclick = => toggle_hidden(@last_div, 'output')
  fix_level_one: ->
    className = if @ok then "ok" else "not_ok"
    @container.slice(-2,-1)[0].className += " border-#{className}"
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
    return if not line?.length
    action = @find line
    return false if not action
    @same_action = action[0] is @last_action
    @last_action = action[0]
    try action[0].apply(@, action[1]) catch err
      console.log action.toString()
      console.log err.stack if err.stack
    window.parent.usdlc.instrument_window.resize_to_fit()

window.instrument = ->
  instrument = new Instrument()

  url = "/server/http/gwt.coffee#{window.location.search}"
  instrument.html('again',
    "<a href='#{window.location.href}'>again</a>")
  request = new XMLHttpRequest()
  previous_length = 0
  request.onreadystatechange = ->
    return if request.readyState <= 2
    try
      text = request.responseText.substring(previous_length)
      previous_length = request.responseText.length
    catch e then text = ''
    error = null
    if is_complete = (request.readyState is 4)
      if request.status isnt 200 then alert(error = request.statusText)
    instrument.display(line) for line in text.split(/\s*\r*\n/)
  request.open 'GET', url, true
  request.send null
