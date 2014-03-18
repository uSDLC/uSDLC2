# Copyright (C) 2013 paul@marrington.net, see GPL for license
processes = require 'processes'; fs = require 'fs'

gwt.rules(
  /execute '(.*)'/, (cmd) -> @process.execute(cmd)
)

class Process
  constructor: (@exec_type = 'shell', cwd = '.') ->
    @process = processes()
    @process.options.cwd = cwd
    
  shell: (cmd, onExit = ->) ->
    @process.cmd cmd, onExit
    gwt.cleanup (next) =>
      @process.proc.stdin.end()
      @process.kill()
      next()
    return @
    
  execute: (cmd) ->
    switch @exec_type
      when 'shell'
        @shell cmd, (error) => gwt.check_for_error(error)
      else
        gwt.fail "Bad exec type #{@exec_type} for '#{cmd}"
    return @
  
  repl: (cmd, onExit) ->
    console.log "REPL: "+cmd
    @shell cmd, (error) =>
      if gwt.finished then onExit(error)
      else gwt.cleanup (next) -> onExit(error); next()
    return @

module.exports = (type) -> new Process(type)