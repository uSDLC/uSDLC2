# Copyright (C) 2013 paul@marrington.net, see GPL for license
processes = require 'processes'

gwt.rules(
  /execute '(.*)'/, (cmd) -> @process.execute(cmd)
)

class Process
  constructor: (@exec_type) ->
    @process = processes()
  exec: (cmd) ->
    switch @exec_type
      when 'shell'
        @process.cmd cmd, (error) -> gwt.check_for_error(error, cmd)
      else
        gwt.fail("No exec type #{@exec_type} for '#{cmd}")

modules.export = (type) -> new Process(type)