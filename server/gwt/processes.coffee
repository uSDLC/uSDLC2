# Copyright (C) 2013 paul@marrington.net, see GPL for license
processes = require 'processes'

gwt.rules(
  /execute '(.*)'/, (cmd) -> @process.execute(cmd)
)

class Process
  constructor: (@exec_type = 'shell') ->
    @process = processes()
  execute: (cmd) -> gwt.queue @, ->
    switch @self.exec_type
      when 'shell'
        @self.process.cmd cmd, (error) =>
          @check_for_error(error)
      else
        @fail(
          "Invalid exec type #{@self.exec_type} for '#{cmd}")
    return @

module.exports = (type) -> new Process(type)