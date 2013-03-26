# Copyright (C) 2013 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license
path = require 'path'; fs = require 'file-system'

module.exports =
  # set the current working directory to be dev, not base. Since NODE_PATH
  # is already set this should only effect http requests and the like
  pre: (environment) ->
    # process.chdir(process.env.uSDLC_base_path =
    #   environment.base_dir = path.normalize fs.base '..')

  # call after server has started listening for connections
  post: (environment) ->

# # set new patterns to decide on script domain (client, server, system)
# setDomain = require('set-domain')
# setDomain.patterns.push [/\Wclient\W/, domains.client]
# setDomain.activate()
