# Copyright (C) 2013 paul@marrington.net, see GPL for license
cws = require 'boot/create-ws-server'; npm = require 'npm'
cfs = require 'boot/create-faye-server'

module.exports =
  pre: (environment) ->
  post: (environment) ->
    cws environment, -> cfs environment, ->
      environment.faye.clients = {}
      environment.faye.bayeux.on 'handshake', (id) ->
        environment.faye.clients[id] = id
      environment.faye.bayeux.on 'disconnect', (id) ->
        delete environment.faye.clients[id]
      setTimeout ( ->
        return if Object.keys(environment.faye.clients).length
        npm 'open', (error, open) =>
          open "http://localhost:#{environment.port}"
      ), 5000
      console.log "\nReady... "+
      "(http://localhost:#{environment.port})\n"
