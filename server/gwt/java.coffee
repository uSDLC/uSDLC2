# Copyright (C) 2013 paul@marrington.net, see GPL for license
queue = require 'queue'; dirs = require 'dirs'

class Java
  constructor: (@options, next) ->
    @options.dir ?= '.'
    @options.out ?= '.'
    dirs.mkdirs @options.out, next
    @shell = gwt.process('shell', @options.dir)
    
  compile: (files..., next) ->
    cmd = "javac -d #{@options.out} #{files.join(' ')}"
    @shell.execute cmd
  
  run: (args..., next) ->
    cmd = "java -classpath #{@options.out} #{@options.main}"
    @shell.execute cmd
  
module.exports = (options) -> new Java(options)