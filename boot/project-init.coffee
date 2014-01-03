# Copyright (C) 2013 paul@marrington.net, see GPL for license
cws = require('boot/create-ws-server')
cfs = require('boot/create-faye-server')

module.exports =
  pre: (environment) ->
  post: (environment) ->
    cws environment, -> cfs environment, ->
      console.log '\nReady...\n'
