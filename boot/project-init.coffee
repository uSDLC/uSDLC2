# Copyright (C) 2013 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license

module.exports =
  # set the current working directory to be dev, not base. Since NODE_PATH
  # is already set this should only effect http requests and the like
  pre: (environment) ->

  # call after server has started listening for connections
  post: (environment) ->
