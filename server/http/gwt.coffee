# Copyright (C) 2012,13 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license
querystring = require 'querystring'; processes = require 'processes'
stream = require('stream')

module.exports = (exchange) ->
  gwt = processes('gwt')
  # Output will be wiki text as written by stdout and stderr
  exchange.response.setHeader "Content-Type", "application/octet-stream"
  exchange.request.url.query.forked = true
  query = gwt.decode_query(exchange.request.url.query)
  gwt.node query..., -> exchange.response.end()
  # We have forked the new process. It communicates back as messages
  # which we have to send to the browser when said browser is ready.
  queue = []; can_write = true
  gwt.proc.on 'message', (data) ->
    return queue.push(data) unless can_write
    can_write = exchange.response.write(data)

  exchange.response.on 'drain', ->
    while queue.length
      return if not exchange.response.write(queue.shift())
    can_write = true
