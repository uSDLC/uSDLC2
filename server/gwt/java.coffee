# Copyright (C) 2013 paul@marrington.net, see GPL for license
Compiler = require 'gwt/compiler'; path = require 'path'

class Java extends Compiler
  type:      'java'
  source_re: /.*\.java$/
  target_ext: '.class'
  exe_ext:    ""

  compile_commands: (sources) =>
    cp = "-classpath #{@opts.out}"
    return ["javac #{cp} -d #{@opts.out} #{sources.join(' ')}"]
      
  run_command: (args...) =>
    cp = "-classpath #{@opts.out}"
    main = path.basename @opts.main
    return "java #{cp} #{main} #{args.join(' ')}"
  
module.exports = (opts) -> new Java(opts)