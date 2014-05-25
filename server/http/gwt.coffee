# Copyright (C) 2012,13 paul@marrington.net, see /GPL license
querystring = require 'querystring'
processes = require 'processes'; stream = require 'stream'

host = "http://#{require('system').hosts()[0]}:"
host += process.environment.port

procs = {}

module.exports = (ws) ->
  gwt = processes('gwt')
  # Output will be wiki text as written by stdout and stderr
  query = gwt.decode_query ws.url.query
  query.push "host=#{host}"
  gwt.node query..., -> ws.close()
  gwt.proc.on 'message', (data) -> ws.send data
  ws.on 'message', (data) -> gwt.proc.send data