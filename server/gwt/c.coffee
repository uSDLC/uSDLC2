# Copyright (C) 2014 paul@marrington.net, see GPL for license
Compiler = require 'gwt/compiler'; system = require 'system'

class C extends Compiler
  type:      'c'
  source_re:  /.*\.c$/
  target_ext: '.o'
  exe_ext:   system.executable_extension

  compile_commands: (sources, targets) ->
    cmds = []; targets = targets[0..-1]
    for source in sources
      tgt = targets.shift()
      cmds.push "gcc -iquote . -Wall -o #{tgt} -c #{source}"
    return cmds
  
  link_command: (inputs...) ->
    inputs = (input.join(' ') for input in inputs)
    return "gcc -o #{@opts.main} #{inputs.join(' ')}"
    
  run_command: => @opts.main
  
module.exports = (opts) -> new C(opts)
