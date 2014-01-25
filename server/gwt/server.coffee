# Copyright (C) 2013 paul@marrington.net, see GPL for license
_ = require 'underscore'; processes = require 'processes'
gwt = require 'gwt'; url = require 'url'
dirs = require 'dirs'; Internet = require 'internet'
util = require 'util'; send = require 'send'
strings = require 'common/strings'

gwt.rules(
  /a running (.*) server/, (name) -> gwt.server()[name].start()
  /start a (.*) server/, (name) -> gwt.server()[name].start()
)

class Server
  constructor: (@name, options) ->
    _.extend @, options
    # helper to get to internet for the server
    @net = new Internet(options.url)
    @start_command ?= module.exports.start_command
    @stop_url ?= module.exports.stop_url
  # start the active or named server
  start: ->
    if @running_instance
      return gwt.pass("#{@name} already running")
    dirs.in_directory @dir, =>
      @running_instance = processes().cmd @start_command, =>
    check = =>
      @net.read_response => gwt.pass()
      @net.get @ping ? '', (error) =>
        if error
          @running_instance = null
          return gwt.fail \
          "Server #{@name} did not start (#{error})"
    setTimeout check, 2000
    gwt.on_exit (next) =>
      return if not @running_instance
      if @stop_url and @stop_url[0] isnt '#'
        @running_instance.on 'exit', =>
          @running_instance = null
          next()
        @net.get @stop_url, ->
          "Server did not exit as anticipated"
      else if @stop_command
        processes().cmd @stop_command, =>
          @running_instance = null
          next()
      else
        @running_instance.kill()
        next()
  # retrieve or infer port number
  port: -> url.parse(@url).port

  get: (cmd, args, next) ->
    key = cmd.split('/').slice(-1)[0].split('.')[0]
    @net.get_json cmd, query: args, (error, @last_response) =>
      return gwt.fail(error) if error
      if not @last_response
        return gwt.fail("No JSON response for #{cmd}")
      if @last_response?.error
        return gwt.fail(@last_response.error)
      return next(@last_response) if next
      gwt.pass(strings.from_map(@last_response))

  bin: (cmd, args) ->
    key = cmd.split('/').slice(-1)[0].split('.')[0]
    @net.get_response cmd, query: args,
    (err, @last_response) =>
      return gwt.fail(err) if err
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
            result.push \
              "Expecting type #{expecting}, received #{ext}"
    return gwt.pass() if not result.length
    gwt.fail result.join '\n'

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
      module.exports[name] =
        module.exports[name.replace(/\s/g, '_')] =
          new Server name, options
  start_command: "./go.sh server mode=gwt config=debug"
  stop_url: 'server/http/terminate.coffee?signal=SIGKILL'
