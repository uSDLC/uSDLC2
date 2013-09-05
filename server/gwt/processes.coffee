# Copyright (C) 2013 paul@marrington.net, see GPL for license
processes = require 'processes'

gwt.rules(
  /execute '(.*)'/, (cmd) -> @process.execute(cmd)
)

class Process
  constructor: (@exec_type = 'shell') ->
    @process = processes()
  execute: (cmd) -> @async ->
    switch @exec_type
      when 'shell'
        @process.cmd cmd, (error) -> gwt.check_for_error(error)
      else
        gwt.fail("Invalid exec type #{@exec_type} for '#{cmd}")
    return @

module.exports = (type) -> new Process(type)