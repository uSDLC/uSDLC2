# Copyright (C) 2013 paul@marrington.net, see GPL for license
Compiler = require 'gwt/compiler'

class Java extends Compiler
  type:      'java'
  source_re: /.*\.java$/
  target_ext: '.class'
  exe_ext:    ""

  compile_commands: (sources) ->
    cp = "-classpath #{@opts.out}"
    return ["javac #{cp} -d #{@opts.out} #{sources.join(' ')}"]
      
  run_command: (args...) ->
    cp = "-classpath #{@opts.out}"
    return "java #{cp} #{@opts.main} #{args.join(' ')}"
  
module.exports = (opts) -> new Java(opts)