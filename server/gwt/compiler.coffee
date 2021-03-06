# Copyright (C) 2013 paul@marrington.net, see GPL for license
dirs = require 'dirs'; path = require 'path'
processes = require 'processes'; gwt = require 'gwt'
require 'common/strings'; walk = require 'walk'
files = require 'files'; newer = require 'newer'

class Compiler
  constructor: (@opts) ->
    @opts.dir ?= '.'
    @opts.out ?= '.'
    @shell = processes()
    @shell.options.cwd = @opts.dir
    @sources = []; @targets = []; @unchanged = []
    @precompile = [ (next) => dirs.mkdirs @opts.out, next ]
    
    @prepare = (source, target) ->
      if newer(source, target)
        @sources.push source
        @targets.push target
      else
        @unchanged.push target
    
    gwt.file_processor[@type] = (name, next) =>
      main = @target path.basename(name), @target_ext
      @opts.main = files.change_ext main, @exe_ext
      @prepare(name, main)
      next()
      
    @building = [ (next) =>
      return next() if not @sources.length
      cmds = @compile_commands @sources, @targets
      do compile = =>
        return next() if not cmds.length
        console.log cmd = cmds.shift()
        @shell.cmd cmd, compile
    ]
        
    if @link_command
      @building.push (next) =>
        cmd = @link_command(@targets, @unchanged)
        @shell.cmd cmd, next
            
  compile: (list..., next) ->
    do go = =>
      return next() if not list.length
      source = list.shift()
      files.is_dir source, (err, is_dir) =>
        if is_dir
          walk source, go, (file, stats, next) =>
            from = "#{source}#{file}"
            if @source_re.test(from)
              to = @target(file, @target_ext)
              @prepare(from, to)
            next()
        else
          target = @target path.basename(source)
          @prepare(source, target)
          go()
          
  build: (done) ->
    @precompile.push @building...
    do go = =>
      return done() if not @precompile.length
      @precompile.shift()(go)
  
  # given a source relative to the current source base
  target: (source, ext = @target_ext) =>
    return path.join @opts.out, files.change_ext source, ext
  
  run: (args..., finished) ->
    console.log cmd = @run_command(args...)
    @shell.cmd cmd, finished
  
module.exports = Compiler
