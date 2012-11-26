# Copyright (C) 2012,13 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license
child = require('child_process')
    
# Fork off a separate node process to run the V8 scripts in a separate space
fork = (script, request, response) ->
  # Output will be play text as written by stdout and stderr
  response.setHeader "Content-Type", "text/plain"
  script = "uSDLC2/scripts/#{script}.coffee"

  # child process is gwt with arguments dir, scripts... running in base directory and environment
  process = child.fork 'uSDLC2/scripts/coffee.js',
    [script, request.url.pathname, request.url.query, request.url.hash], {
      request.url.pathname
      request.url.query
      request.url.hash
    ], {
      cwd: process.cwd()
      env: process.env
      stdio: ['ignore', response, response]
    }
  process.on 'exit', -> response.end()
  
# Spawn off a separate OS process
spawn = (program, request, response) ->
  # Output will be play text as written by stdout and stderr
  response.setHeader "Content-Type", "text/plain"

  # child process is gwt with arguments dir, scripts... running in base directory and environment
  process = child.spawn program, 
    [request.url.pathname, request.url.query, request.url.hash], {
      cwd: process.cwd()
      env: process.env
      stdio: ['ignore', response, response]
    }
  process.on 'exit', -> response.end()


module.exports = {fork, spawn}