# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
dirs = require "dirs"

module.exports = (environment) ->
  require('config/base')(environment)
  require(dirs.node('config/production'))(environment)
