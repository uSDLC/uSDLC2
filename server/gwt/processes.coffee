# Copyright (C) 2013 paul@marrington.net, see GPL for license
processes = require 'processes'

gwt.rules(
  /execute '(.*)'/, (cmd) -> @process.execute(cmd)
)

class Process
  constructor: (@exec_type) ->
    @process = processes()
  exec: (cmd, on_exit = ->) ->
    switch @exec_type
      when 'shell'
        @process.cmd cmd, on_exit #(error/null)
      else
        gwt.fail("No exec type #{@exec_type} for '#{cmd}")
    return @

module.exports = (type) -> new Process(type)