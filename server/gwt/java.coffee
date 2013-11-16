# Copyright (C) 2013 paul@marrington.net, see GPL for license
queue = require 'queue'; dirs = require 'dirs'
processes = require 'processes'; gwt = require 'gwt'
path = require 'path'

class Java
  constructor: (@opts) -> gwt.actions.push =>
    @opts.dir ?= '.'
    @opts.out ?= '.'
    @shell = processes()
    @shell.options.cwd = @opts.dir
    dirs.mkdirs @opts.out, -> gwt.next()
    
  compile: (files...) -> gwt.actions.push =>
    cp = "-classpath #{@opts.out}"
    cmd = "javac #{cp} -d #{@opts.out} #{files.join(' ')}"
    @shell.cmd cmd, -> gwt.next()
  
  run: (main, args...) -> gwt.add =>
    @opts.main = main
    @shell.cmd @command_line(args...), ->

  command_line: (args...) ->
    cp = "-classpath #{@opts.out}"
    "java #{cp} #{@opts.main} #{args.join(' ')}"
    
  class_name: (file) -> path.basename file, '.java'
  
module.exports = (opts) -> new Java(opts)