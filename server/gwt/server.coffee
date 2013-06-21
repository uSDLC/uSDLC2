# Copyright (C) 2013 paul@marrington.net, see GPL for license
_ = require 'underscore'; processes = require 'processes'; gwt = require 'gwt'
url = require 'url'; dirs = require 'dirs'; internet = require 'internet'
util = require 'util'; send = require 'send'; strings = require 'common/strings'

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
      @net.read_response => gwt.pass()
      @net.get @ping ? '', (error) =>
        if error
          @running_instance = null
          return gwt.fail "Server #{@name} did not start (#{error})"
    setTimeout check, 2000
    gwt.on_exit (next) =>
      return if not @running_instance
      if @stop_url[0] isnt '#'
        @running_instance.on 'exit', =>
          @running_instance = null
          next()
        @net.get @stop_url, -> "Server did not exit as anticipated"
      else
        @running_instance.kill()
        next()
  # retrieve or infer port number
  port: -> url.parse(@url).port

  get: (cmd, args, next) ->
    key = cmd.split('/').slice(-1)[0].split('.')[0]
    @net.get_json cmd, query: args, (error, results) =>
      gwt[key] = results
      return gwt.fail(error) if error
      return gwt.fail("No JSON response for #{cmd}") if not results
      return gwt.fail(results.error) if results?.error
      return next(results) if next
      gwt.pass(strings.from_map(results))

  bin: (cmd, args) ->
    key = cmd.split('/').slice(-1)[0].split('.')[0]
    @net.get cmd, query: args, (error, results) =>
      gwt[key] = results
      return gwt.fail(error) if error
      gwt.pass(cmd)

  check_get: (contents, against) ->
    result = []
    for key, value of against
      switch key
        when 'size'
          bytes = contents.length
          if bytes < value[0] or bytes > value[1]
            result.push "Size #{bytes} outside range #{value}"
        when 'ext'
          ext = @net.response.headers['content-type']
          value = ".#{value}" if value.indexOf('.') is -1
          expecting = send.mime.lookup value
          if ext isnt expecting
            result.push "Expecting type #{expecting}, received #{ext}"
    return gwt.pass() if not result.length
    gwt.fail result.join '\n'

module.exports =
  # dictionary of known servers accessed by name. Each record has:
  #   url: base url (e.g. http://localhost:9020)
  #   ping: relative url to ping for live check
  #   dir: base directory to run server from (usually relative to uSDLC2)
  #   start_command: command to start the server (defaults to './go server')
  #   stop_url: relative url to stop the server
  # add to the list of known servers
  add: (servers) ->
    for name, options of servers
      module.exports[name] =
        module.exports[name.replace(/\s/g, '_')] = new Server name, options
  start_command: "./go server mode=gwt config=debug"
  stop_url: 'server/http/terminate.coffee?signal=SIGKILL'
