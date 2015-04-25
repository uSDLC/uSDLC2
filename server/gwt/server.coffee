# Copyright (C) 2013 paul@marrington.net, see GPL for license
_ = require 'underscore'; processes = require './processes'
gwt = require 'gwt'; url = require 'url'
dirs = require 'dirs'; Internet = require 'internet'
util = require 'util'; send = require 'send'
strings = require 'common/strings'

class Server
  constructor: (@name, @options) ->
    # helper to get to internet for the server
    @options.start_command ?= module.exports.start_command
    @options.stop_url ?= module.exports.stop_url
  net: ->
    cookies = @internet?.cookies
    @internet = new Internet(@options.url)
    @internet.cookies = cookies
    return @internet
  # start the active or named server
  start: (options = {}) ->
    @options[k] = v for k,v of options
    if @running_instance
      return gwt.pass("#{@name} already running")
    dirs.in_directory @options.dir, =>
      # always use bash - as uSDLC2 windows has a version in the path
      cmd = ["bash", "-lc", "#{@options.start_command}"]
      @running_instance = processes().spawn cmd..., =>
        
    if @options.ready
      gwt.maximum_step_time = 300
      gwt.expect @options.ready
    else
      check = =>
        (net = @net()).once 'finish', => gwt.pass()
        net.get @ping ? '', (error) =>
          if error
            @running_instance = null
            return gwt.fail \
            "Server #{@name} did not start (#{error})"
      setTimeout check, 2000
    gwt.on_exit (next) =>
      return if not @running_instance
      if @options.stop_url and @options.stop_url[0] isnt '#'
        @running_instance.on 'exit', =>
          @running_instance = null
          next()
        @net().get @options.stop_url, ->
          "Server did not exit as anticipated"
      else if @options.stop_command
        processes().shell @options.stop_command, =>
          @running_instance = null
          next()
      else
        @running_instance.kill()
        next()
  # retrieve or infer port number
  port: -> url.parse(@options.url).port
  
  check_response: (cmd, error, @last_response, next) ->
    return gwt.fail(error.toString()) if error
    if not @last_response
      return gwt.fail("No JSON response for #{cmd}")
    if @last_response?.error
      return gwt.fail(@last_response.error)
    return next(@last_response) if next
    gwt.pass(strings.from_map(@last_response))

  get: (cmd, args..., next) ->
    @net().get_json cmd, query: args[0], (err, response) =>
      @check_response cmd, err, response, next
  
  post: (cmd, args..., object, next) ->
    @net().post_json cmd, object, query: args[0], (err, resp) =>
      try @check_response cmd, err, JSON.parse(resp), next
      catch err then gwt.fail err
      
  bin: (cmd, args) ->
    (net = @net()).read_response (err, @last_response) =>
      if err then gwt.fail(err) else gwt.pass(cmd)
    net.get cmd, query: args, ->

module.exports =
  # dictionary of known servers accessed by name.
  # Each record has:
  #   url: base url (e.g. http://localhost:9020)
  #   ping: relative url to ping for live check
  #   dir: base directory (usually relative to uSDLC2)
  #   start_command: for server (defaults to './go.sh server')
  #   stop_url: relative url to stop the server
  # add to the list of known servers
  add: (servers) ->
    for name, options of servers
      if not gwt.servers[name]
        gwt.servers[name] =
          gwt.servers[name.replace(/\s/g, '_')] =
            new Server name, options
  start_command: "./go.sh server mode=gwt terminate=allowed"
  stop_url: 'server/http/terminate.coffee?signal=SIGKILL'
