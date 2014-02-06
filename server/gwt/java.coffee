# Copyright (C) 2013 paul@marrington.net, see GPL for license
dirs = require 'dirs'; path = require 'path'
processes = require 'processes'; gwt = require 'gwt'
require 'common/strings'; walk = require 'walk'

class Java
  constructor: (@opts) -> gwt.preactions.push =>
    @opts.dir ?= '.'
    @opts.out ?= '.'
    @shell = processes()
    @shell.options.cwd = @opts.dir
    dirs.mkdirs @opts.out, -> gwt.next()
    
  compile: (files...) ->
    list = []
    for source in files
      ((source) =>
        gwt.preactions.push =>
          walk.newer source, @opts.out, /.*\.java$/, (files) ->
            list.push files...
            gwt.next()
      )(source)
    gwt.preactions.push =>
      return gwt.next() if not list.length
      cp = "-classpath #{@opts.out}"
      cmd = "javac #{cp} -d #{@opts.out} #{list.join(' ')}"
      console.log cmd
      @shell.cmd cmd, -> gwt.next()
  
  run: (main, args...) -> gwt.add =>
    @opts.main = main
    @shell.cmd @command_line(args...), ->

  command_line: (args...) ->
    cp = "-classpath #{@opts.out}"
    "java #{cp} #{@opts.main} #{args.join(' ')}"
    
  class_name: (file) -> path.basename file, '.java'
  
module.exports = (opts) -> new Java(opts)
