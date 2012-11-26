# Copyright (C) 2012,13 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license
child = require 'child_process'
    
class Proc # proc = require('proc')() # sets default streaming and options
  constructor: () ->
    @streamer = {resume:(->), pause:(->)}
    @onExit = => @streamer.resume()
    @options =
      cwd: process.cwd()
      env: process.env
      stdio: ['ignore', process.stdout, process.stderr]
      
  # proc = Proc().stream(gwt)
  stream: (@streamer) -> return this
  # proc = Proc().pause(stream.pause)
  pause: (pause) -> @streamer.pause = pause; return this
  # proc = Proc().resume(respond.end)
  resume: (resume) -> @streamer.resume = resume; return this
    
  # Fork off a separate node process to run the V8 scripts in a separate space
  fork: (script, args...) ->
    @streamer.pause()
    child.fork('uSDLC2/scripts/coffee.js', [script, args...], @options).on 'exit', @onExit
  
  # Spawn off a separate OS process
  spawn: (program, args...) ->
    @streamer.pause()
    console.log "#{program} -- #{args}"
    child.spawn(program, args, @options).on 'exit', -> @onExit  

module.exports = -> new Proc()