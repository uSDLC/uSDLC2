# Copyright (C) 2013 paul@marrington.net, see GPL for license
_ = require 'underscore'; processes = require 'processes'; gwt = require 'gwt'
url = require 'url'; dirs = require 'dirs'; internet = require 'internet'

class Server
  # dictionary of known servers accessed by name. Each record has:
  #   url: base url (e.g. http://localhost:9020)
  #   ping: relative url to ping for live check
  #   dir: base directory to run server from (usually relative to uSDLC2)
  #   start: command to start the server (defaults to './go server')
  #   stop: repative url to stop the server
  # add to the list of known servers
  add: (servers, active) ->
    _.extend @, servers
    @activate active if active
  # server we are currently working with
  activate: (@name) ->
    return gwt.fail "No server '#{@name}'" if not (@active = @[@name])
    @net.base = @active.url
  # helper to get to internet for the server
  net: internet()
  # start the active or named server
  start: (server = @name) ->
    @activate server
    return gwt.pass("#{@name} already running") if @active.running
    dirs.rmdirs "#{@active.dir}/files/99999999999999", =>
    dirs.in_directory @active.dir, =>
      starter = @active.start ? "./go server config=debug"
      @active.instance = processes().cmd starter, =>
    check = =>
      @net.get @active.ping ? '', (err) =>
        return gwt.fail "Server #{@name} did not start (#{err})" if err
        server.running = true
        gwt.pass "#{@name} running"
    setTimeout check, 2000
    gwt.on_exit (next) =>
      @active.instance.on 'exit', ->
        server.running = false
        next()
      @net.get @active.stop ? 'server/http/terminate.coffee?signal=SIGKILL', ->
  # retrieve or infer port number
  port: (server = @name) ->
    @activate server
    return url.parse(@active.url).port

module.exports = new Server