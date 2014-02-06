# Copyright (C) 2014 paul@marrington.net, see GPL for license
gwt = require 'gwt'; http = require 'http'; npm = require 'npm'
gwt.browsers = {}
port = 19008
# This is called by the system under test
module.exports = (ws) ->
  name = ws.url.query.usdlc2_browser_manager
  return if not name
  host = gwt.browsers[name] ?= messages: []
  host.send = (message) -> ws.send message
  host.on 'message', (message) -> host.messages.push message
  
# and the following is called by gwt to start the required
# websocket server, start up the browser and support the
# instrumentation
start_ws_server = ->
  http_server = http.createServer (request, response) ->
    while true
      try http_server.listen ++port; break
      catch e then console.log "Port #{port - 1} unavailable"
      
      npm 'ws', (error, ws) ->
        options = server: http_server
        (new ws.Server(options)).on 'connection', (wss) ->
          wss.url = url.parse wss.upgradeReq.url, true
          files.find wss.url.pathname, (filename) ->
            filename ?= wss.url.pathname
            action = require filename
            action.apply(gwt, wss)
          
class Browser
  constructor: (@name, @url) ->
    sep = (@url.indexOf('?') == -1) ? '?' : '&'
    @url += sep+"usdlc2-port="+port
    @host = gwt.browsers[@name]
  platform: (@_platform, next) ->
    @_platform = null if @_platform is 'default'
    switch platform
      when 'phantomjs'
      else
        npm 'open', (@_open) -> next()
  open: (url) -> @_open url, @_platform, => @onClose()
  onClose: ->

# start up the specified browser (defaults to system)
# Returns a browser object for further instrumentation
module.exports.connect = (name, url) ->
  return null if not gwt.browsers[name]
  return module.exports[name] ?= new Browser(name, url)
