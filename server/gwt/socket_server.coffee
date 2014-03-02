# Copyright (C) 2014 paul@marrington.net, see GPL for license
net = require 'net'; line_reader = require 'line_reader'
Event_Emitter = require('events').eventEmitter

module.exports = (port, on_connection) ->
  console.log "Starting socker server on #{port}"
  server = net.createServer (socket) ->
    console.log "Socker server #{port} connection made"
    read_line = (client_id) ->
      read_line = (line) -> console.log(line)
      on_connection client_id, (cmd, params...) ->
        socket.write("#{cmd}\0#{params.join('\0')}\n")
    line_reader socket, (line) -> read_line(line)
    module.exports.close = ->
      console.log "Closing socket client"
      socket.end('__end__\n')
  server.on 'error', (error) ->
    console.log "Socker server #{port} error", error
  server.listen port, ->
    console.log "Socket server listening on #{port}"
  gwt.cleanup (next) -> module.exports.close(); next()
