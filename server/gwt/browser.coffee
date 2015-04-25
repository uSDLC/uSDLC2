# Copyright (C) 2014 paul@marrington.net, see GPL for license
gwt = require 'gwt'; http = require 'http'; npm = require 'npm'
Phantom = require 'phantom'; wait_for = require 'wait_for'
EventEmitter = require('events').EventEmitter
url = require 'url'; files = require 'files'
system = require 'system'
gwt.browsers = {}; port = 19008
# This is called by the system under test
module.exports = (ws) ->
  name = ws.url.query.name
  return if not name or not gwt.browsers[name]
  host = gwt.browsers[name]
  ws._events = host._events # event proxy
  host.inject = (func) ->
    ws.send "(#{func.toString()}).call(gwt);"
  host.test = (data) ->
    gwt.expect /^Passed: /, /^Failed: /
    host.inject data
  host.on 'message', (message) ->
    process.stdout.write message
  host.emit 'open'
  
# and the following is called by gwt to start the required
# websocket server, start up the browser and support the
# instrumentation
ws_server_ready = wait_for (started) ->
  npm 'ws', (error, ws) ->
    started(error) if error
    do listen = ->
      options = host: 'localhost', port: ++port
      web_socket = new ws.Server options, (err) ->
        return process.nextTick listen if err
      web_socket.on 'connection', (wss) ->
        wss.url = url.parse wss.upgradeReq.url, true
        files.find wss.url.pathname, (filename) ->
          filename ?= wss.url.pathname[1..-1]
          action = require filename
          action.call(gwt, wss)
      started()
          
# events are: error(error), close(code, message),
# message(data, flags:binary), ping(data, flags:binary),
# pong(data, flags:binary), open()
class Browser extends EventEmitter
  constructor: (@name) ->
    @platform_open = @browser_open
  platform: (@platform_name) ->
    switch @platform_name
      when 'phantomjs'
        gwt.options.maximum_step_time = 360000
        @platform_open = (url) =>
          phantom = new Phantom url, =>
          phantom.onClose = => @onClose()
      else
        @platform_name = null if @platform_name is 'default'
        @platform_open = @browser_open
  open: (@url, options) ->
    ws_server_ready (error) =>
      @emit 'error', error if error
      sep = if @url.indexOf('?') == -1 then '?' else '&'
      full_url = @url+sep+"usdlc2-name=#{@name}&usdlc2-port=#{port}"
      full_url += "&usdlc2-instrumentation=#{gwt.options.host}"
      full_url += "&usdlc2-retain-page=true" if options?.retain
      @platform_open full_url
    return @ # for page = gwt.browser().page(name).open(url)
  send: (message) -> # filled in on connection
  onClose: ->
    @url = null
  # Internal
  browser_open: (url) ->
    npm 'open', (error, open) =>
      open url, @platform_name, => @onClose()

# start up the specified browser (defaults to system)
# Returns a browser object for further instrumentation
module.exports.page = (name, platform) ->
  instance = gwt.browsers[name] ?= new Browser(name)
  instance.platform(platform) if platform
  return instance
  
module.exports.open = (url, opts={retain:false}) ->
  return @current_page if @current_page?.url is url
  @current_page = module.exports.page('live')
  @current_page.open url, opts
  @current_page.once 'open',  -> gwt.pass()
  @current_page.once 'error', -> gwt.fail()
  return @current_page
