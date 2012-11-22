# Copyright (C) 2012,13 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license
spawn = require('child_process').spawn
spawn_options = {cwd:process.cwd(), env:process.env,stdio:'inherit'}

restarting = false
usdlc = node_inspector = null
args = ['--debug', 'server/coffee.js', 'server/server.coffee'].concat process.argv[2..-1]

# start uSDLC if not running else kill it forcing a restart  
start_usdlc = ->
  return kill_usdlc() if usdlc
  usdlc = spawn "node", args, spawn_options
  usdlc.on 'exit', (code, signal) ->
    usdlc = null
    # if uSDLC dies, kill node-inspector
    node_inspector.kill() if node_inspector
  # fire of node-inspector after a 5 second delay so application can stabilise
  setTimeout start_node_inspector, 5000

# start node-inspector once the main app is running and stabilised
start_node_inspector = ->
  node_inspector = spawn "node-inspector", [], spawn_options
  node_inspector.on 'exit', ->
    # if node-inspector exits, start everything again
    restarting = false
    node_inspector = null
    start_usdlc()

kill_usdlc = ->
  return if restarting or not usdlc
  restarting = true
  console.log 'restarting server...'
  usdlc.kill()

watch = require('fs').watch

# if server code changes, restart server and node-inspector
watch 'server', -> kill_usdlc()
watch 'common', -> kill_usdlc()

console.log "debug mode - restarts on changes

# kick everything off by starting the server for the first time
start_usdlc()