# Copyright (C) 2012,13 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license
querystring = require 'querystring'; processes = require 'processes'

module.exports = (exchange) ->
  gwt = processes('gwt')
  # Output will be wiki text as written by stdout and stderr
  exchange.response.setHeader "Content-Type", "text/plain"
  query = gwt.decode_query(exchange.request.url.query)
  # gwt.options.stdio = ['ignore', exchange.response, exchange.response]
  gwt.node query..., -> exchange.response.end()
