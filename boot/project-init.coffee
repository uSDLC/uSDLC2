# Copyright (C) 2013 paul@marrington.net, see GPL for license

module.exports =
  pre: (environment) ->
  post: (environment) ->
    require('boot/create-ws-server')(environment)
    require('boot/create-faye-server')(environment)
