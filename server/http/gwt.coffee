# Copyright (C) 2012,13 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license
querystring = require 'querystring'; processes = require 'processes'

module.exports = (exchange) ->
  gwt = processes("$uSDLC_node_path/boot/load.js")
  # Output will be wiki text as written by stdout and stderr
  response.setHeader "Content-Type", "text/plain"
  query = exchange.request.query
  query.path ?= exchange.request.url.pathname
  query.hash ?= exchange.request.url.hash
  query = querystring.stringify(exchange.request.query)
  proc.options.stdio = ['ignore', exchange.response, exchange.response]
  proc.node "boot/run", 'gwt', query -> exchange.response.end()
