# Copyright (C) 2013 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license
require! path; require! 'file-system'

module.exports =
  # call before anything is done to initialise the server
  pre: (environment) ->
    process.env.uSDLC_base_path =
      environment.base-dir = path.normalize file-system.base '..'

  # call after server has started listening for connections
  post: (environment) ->

# # set new patterns to decide on script domain (client, server, system)
# setDomain = require('set-domain')
# setDomain.patterns.push [/\Wclient\W/, domains.client]
# setDomain.activate()
