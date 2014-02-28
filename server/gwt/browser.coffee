# Copyright (C) 2014 paul@marrington.net, see GPL for license
gwt = require 'gwt'; http = require 'http'; npm = require 'npm'
Phantom = require 'phantom'; wait_for = require 'wait_for'
EventEmitter = require('events').EventEmitter
url = require 'url'; files = require 'files'
gwt.browsers = {}; port = 19008
# convert variables into a static parameter liste
parameterise = (params...) ->
  result = []
  for param in params
    switch typeof param
      when 'string'
        result.push '"'+param.replace(/"/g, '\\"')+'"'
      when 'function'
        result.push "#{param.toString()}"
      when 'object'
        result.push JSON.stringify(param)
      else
        result.push param.toString()
  return result.join(',')
# This is called by the system under test
module.exports = (ws) ->
  name = ws.url.query.name
  return if not name or not gwt.browsers[name]
  host = gwt.browsers[name]
  ws._events = host._events # event proxy
  host.inject = (params..., data) ->
    switch typeof data
      when 'string' then ws.send data
      when 'function'
        params = parameterise(params...)
        ws.send "(#{data.toString()})(#{params});"
      when 'object' then ws.send JSON.stringify(data)
      else ws.send data.toString()
  host.on 'message', (message) -> process.stdout.write message
  host.emit 'open'
  
# and the following is called by gwt to start the required
# websocket server, start up the browser and support the
# instrumentation
ws_server_ready = wait_for (started) ->
  http_server = http.createServer (request, response) ->
  npm 'ws', (error, ws) ->
    started(error) if error
    options = server: http_server
    web_socket = new ws.Server(options)
    web_socket.on 'connection', (wss) ->
      wss.url = url.parse wss.upgradeReq.url, true
      files.find wss.url.pathname, (filename) ->
        filename ?= wss.url.pathname[1..-1]
        action = require filename
        action.call(gwt, wss)
    started()
  do listen = ->
    process.once 'uncaughtException', (err) ->
      console.log "Port #{port} unavailable", err, err.stack
      listen()
    process.nextTick -> http_server.listen ++port
          
# events are: error(error), close(code, message),
# message(data, flags:binary), ping(data, flags:binary),
# pong(data, flags:binary), open()
class Browser extends EventEmitter
  constructor: (@name) ->
    @platform_open = @browser_open
  platform: (@platform_name, next) ->
    switch @platform_name
      when 'phantomjs'
        gwt.options.maximum_step_time = 360000
        @platform_open = (url) =>
          phantom = new Phantom url, =>
          phantom.onClose = => @onClose()
        next()
      else
        @platform_name = null if @platform_name is 'default'
        @platform_open = @browser_open
        next()
  open: (url, options) ->
    ws_server_ready (error) =>
      @emit 'error', error if error
      sep = if url.indexOf('?') == -1 then '?' else '&'
      url += "#{sep}usdlc2-name=#{@name}&usdlc2-port=#{port}"
      url += "&usdlc2-retain-page" if options?.retain
      @platform_open url
    return @ # for page = gwt.browser().page(name).open(url)
  send: (message) -> # filled in on connection
  onClose: ->
  # Internal
  browser_open: (url) ->
    npm 'open', (error, open) =>
      open url, @platform_name, => @onClose()

# start up the specified browser (defaults to system)
# Returns a browser object for further instrumentation
module.exports.page = (name) ->
  gwt.browsers[name] ?= new Browser(name)
  return gwt.browsers[name]
# Copyright (C) 2014 paul@marrington.net, see GPL for license
gwt = require 'gwt'; http = require 'http'; npm = require 'npm'
Phantom = require 'phantom'; wait_for = require 'wait_for'
EventEmitter = require('events').EventEmitter
url = require 'url'; files = require 'files'
gwt.browsers = {}; port = 19008
# convert variables into a static parameter liste
parameterise = (params...) ->
  result = []
  for param in params
    switch typeof param
      when 'string'
        result.push '"'+param.replace(/"/g, '\\"')+'"'
      when 'function'
        result.push "#{param.toString()}"
      when 'object'
        result.push JSON.stringify(param)
      else
        result.push param.toString()
  return result.join(',')
# This is called by the system under test
module.exports = (ws) ->
  name = ws.url.query.name
  return if not name or not gwt.browsers[name]
  host = gwt.browsers[name]
  ws._events = host._events # event proxy
  host.inject = (params..., data) ->
    switch typeof data
      when 'string' then ws.send data
      when 'function'
        params = parameterise(params...)
        ws.send "(#{data.toString()})(#{params});"
      when 'object' then ws.send JSON.stringify(data)
      else ws.send data.toString()
  host.on 'message', (message) -> process.stdout.write message
  host.emit 'open'
  
# and the following is called by gwt to start the required
# websocket server, start up the browser and support the
# instrumentation
ws_server_ready = wait_for (started) ->
  http_server = http.createServer (request, response) ->
  npm 'ws', (error, ws) ->
    started(error) if error
    options = server: http_server
    web_socket = new ws.Server(options)
    web_socket.on 'connection', (wss) ->
      wss.url = url.parse wss.upgradeReq.url, true
      files.find wss.url.pathname, (filename) ->
        filename ?= wss.url.pathname[1..-1]
        action = require filename
        action.call(gwt, wss)
    started()
  do listen = ->
    process.once 'uncaughtException', (err) ->
      console.log "Port #{port} unavailable", err, err.stack
      listen()
    process.nextTick -> http_server.listen ++port
          
# events are: error(error), close(code, message),
# message(data, flags:binary), ping(data, flags:binary),
# pong(data, flags:binary), open()
class Browser extends EventEmitter
  constructor: (@name) ->
    @platform_open = @browser_open
  platform: (@platform_name, next) ->
    switch @platform_name
      when 'phantomjs'
        gwt.options.maximum_step_time = 360000
        @platform_open = (url) =>
          phantom = new Phantom url, =>
          phantom.onClose = => @onClose()
        next()
      else
        @platform_name = null if @platform_name is 'default'
        @platform_open = @browser_open
        next()
  open: (url, options) ->
    ws_server_ready (error) =>
      @emit 'error', error if error
      sep = if url.indexOf('?') == -1 then '?' else '&'
      url += "#{sep}usdlc2-name=#{@name}&usdlc2-port=#{port}"
      url += "&usdlc2-retain-page" if options?.retain
      @platform_open url
    return @ # for page = gwt.browser().page(name).open(url)
  send: (message) -> # filled in on connection
  onClose: ->
  # Internal
  browser_open: (url) ->
    npm 'open', (error, open) =>
      open url, @platform_name, => @onClose()

# start up the specified browser (defaults to system)
# Returns a browser object for further instrumentation
module.exports.page = (name) ->
  gwt.browsers[name] ?= new Browser(name)
  return gwt.browsers[name]