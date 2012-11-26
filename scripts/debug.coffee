# Copyright (C) 2012,13 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license
spawn = require('child_process').spawn
spawn_options = {cwd:process.cwd(), env:process.env, stdio:'inherit'}

usdlc = node_inspector = null
args = ['--debug', 'uSDLC2/scripts/coffee.js', 'uSDLC2/scripts/server.coffee']
args = args.concat process.argv[2..-1]

# start uSDLC if not running else kill it forcing a restart  
restart = ->
  return usdlc.kill() if usdlc
  usdlc = spawn "node", args, spawn_options
  usdlc.on 'exit', (code, signal) ->
    usdlc = null
    console.log 'restarting server...'
    restart()

watch = require('fs').watch

# if server code changes, restart server and node-inspector
watch 'uSDLC2/server', -> restart()
watch 'uSDLC2/common', -> restart()

console.log 'debug mode - restarts on changes'

# kick everything off by starting the server for the first time
restart()