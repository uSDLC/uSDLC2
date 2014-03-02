# Copyright (C) 2014 paul@marrington.net, see /GPL for license
net = require 'net'; line_reader = require 'line_reader'

module.exports = (name, host, port, commands) ->
  closing = false
  do connect = ->
    console.log "Client #{name} connecting to #{host}:#{port}"
    client = net.connect port:port, host:host, ->
      console.log "Client #{name} connected"
      client.send(name)
    client.send = (line) -> client.write(line+'\n')
    reader = line_reader client, (line) ->
      params = line.split("\0")
      cmd = params.shift()
      if cmd is '__end__'
        closing = true
        return client.close()
      commands[cmd](params...)
    client.on 'close', ->
      setTimeout connect, 1000 if not closing