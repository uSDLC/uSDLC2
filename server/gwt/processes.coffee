# Copyright (C) 2013 paul@marrington.net, see GPL for license
processes = require 'processes'; path = require 'path'
fs = require 'fs'

gwt.rules(
  /execute '(.*)'/, (cmd) -> @process.execute(cmd)
)

class Process
  constructor: (@exec_type = 'shell', cwd = '.') ->
    @process = processes()
    @process.options.cwd = cwd
    
  execute: (cmd) -> gwt.queue @, ->
    switch @self.exec_type
      when 'shell'
        @self.process.cmd cmd, (error) =>
          @check_for_error(error)
      else
        @fail "Bad exec type #{@self.exec_type} for '#{cmd}"
    return @
  
  repl: (cmd, cwd) -> gwt.queue @, ->
    @self.process.options.cwd =
      path.join @self.process.options.cwd, cwd
    @self.process.options.stdio = 'pipe'
    repl = @self.process.cmd cmd, (@failed) =>
      done = -> process.exit(@failed)
      return done() if @finished
      @cleanups.push done
      
    @stdin = repl.proc.stdin
    repl.proc.stdout.pipe process.stdout
    repl.proc.stderr.pipe process.stderr
    
    @cleanups.unshift => @stdin.end()
    @send = (line) -> @stdin.write line
    @send_file = (name, extra) =>
      input = fs.createReadStream(name)
      input.on 'end', => @send extra + '\n'
      input.pipe @stdin, end: false
    return @

module.exports = (type) -> new Process(type)