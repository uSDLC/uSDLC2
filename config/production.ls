# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
require! "file-system"

module.exports = (environment) ->
  require('config/base')(environment)
  require(file-system.node('config/production'))(environment)
