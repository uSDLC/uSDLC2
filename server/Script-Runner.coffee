# Copyright (C) 2012,13 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license
child = require 'child_process'; Processes = require 'Processes'

class Script_Runner
  constructor: (@request, @response) ->
    @proc = Processes().resume -> response.end()
    # Output will be wiki text as written by stdout and stderr
    response.setHeader "Content-Type", "text/plain"
    @args = [request.url.pathname, request.url.query, request.url.hash]
    @proc.options.stdio = ['ignore', response, response]
    
  # Fork off a separate node process to run the V8 scripts in a separate space
  fork: (script) -> # require('Script-Runner')(request, response).fork(program) 
    @proc.fork 'uSDLC2/scripts/coffee.js', ["uSDLC2/scripts/#{script}.coffee", args...]...
  
  # require('Script-Runner')(request, response).spawm(program) 
  spawn: (program) -> @proc.spawn program, args... # Spawn off a separate OS process

module.exports = (request, response) -> new Script_Runner(request, response)