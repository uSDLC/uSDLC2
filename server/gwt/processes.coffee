# Copyright (C) 2013 paul@marrington.net, see GPL for license
processes = require 'processes'; fs = require 'fs'

gwt.rules(
  /execute '(.*)'/, (cmd) -> @process.execute(cmd)
)

class Process
  constructor: (@exec_type = 'shell', cwd = '.') ->
    @process = processes()
    @process.options.cwd = cwd
    
  execute: (cmd) -> gwt.queue @, ->
    switch @exec_type
      when 'shell'
        @process.cmd cmd, (error) =>
          gwt.check_for_error(error)
      else
        gwt.fail "Bad exec type #{@exec_type} for '#{cmd}"
    return @
  
  repl: (cmd, onExit) ->
    gwt.actions.push =>
      @process.cmd cmd, (error) =>
        done = -> onExit(error)
        if @finished then done() else @cleanups.push done
      gwt.cleanups.unshift => @process.proc.stdin.end()
      gwt.next()
    return @

module.exports = (type) -> new Process(type)