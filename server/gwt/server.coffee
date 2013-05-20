# Copyright (C) 2013 paul@marrington.net, see GPL for license
_ = require 'underscore'; processes = require 'processes'; gwt = require 'gwt'
url = require 'url'; dirs = require 'dirs'; internet = require 'internet'
util = require 'util'

class Server
  constructor: (@name, options) ->
    _.extend @, options
    # helper to get to internet for the server
    @net = internet(options.url)
    @start_command ?= module.exports.start_command
    @stop_url ?= module.exports.stop_url
  # start the active or named server
  start: ->
    return gwt.pass("#{@name} already running") if @running_instance
    dirs.in_directory @dir, =>
      @running_instance = processes().cmd @start_command, =>
    check = =>
      @net.get @ping ? '', (error) =>
        if error
          @running_instance = null
          return gwt.fail "Server #{@name} did not start (#{error})"
        gwt.pass "#{@name} running"
    setTimeout check, 2000
    gwt.on_exit (next) =>
      @running_instance.on 'exit', =>
        @running_instance = null
        next()
      @net.get @stop_url, ->
  # retrieve or infer port number
  port: -> url.parse(@url).port
  
  get: (cmd, args) ->
    key = cmd.split('/').slice(-1)[0].split('.')[0]
    @net.get_json cmd, query: args, (error, results) =>
      gwt[key] = results
      return gwt.fail(error) if error
      return gwt.fail("No JSON response for #{cmd}") if not results
      return gwt.fail(results.error) if results?.error
      gwt.pass(cmd)

module.exports = 
  # dictionary of known servers accessed by name. Each record has:
  #   url: base url (e.g. http://localhost:9020)
  #   ping: relative url to ping for live check
  #   dir: base directory to run server from (usually relative to uSDLC2)
  #   start: command to start the server (defaults to './go server')
  #   stop: repative url to stop the server
  # add to the list of known servers
  add: (servers) ->
    for name, options of servers
      module.exports[name] =
        module.exports[name.replace(/\s/g, '_')] = new Server name, options
  start_command: "./go server config=debug"
  stop_url: 'server/http/terminate.coffee?signal=SIGKILL' 
