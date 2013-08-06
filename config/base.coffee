# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
dirs = require "dirs"; files = require "files"

module.exports = (environment) ->
  require(dirs.node('/config/base'))(environment)
  environment.projects = environment.config.projects = dirs.projects

# add a http request processor to capture project/document pages
global.http_processors.unshift (exchange, next_processor) ->
  files.find_in_project exchange.request.url.pathname[1..], (filename) ->
    return next_processor() if not filename
    if exchange.request.url.query.edit?
      # we want to edit, load editor and let it reload project/page
      exchange.request.url.pathname = '/'
      next_processor()
    else
      # send it off as a static file
      exchange.request.filename = filename
      exchange.respond.send_static -> # service ends here
