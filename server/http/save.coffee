# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
fs = require 'fs'; patch = require 'common/patch'
files = require 'files'; steps = require 'steps'

module.exports = (exchange) ->
  name = exchange.request.url.query.name
  name += "/Index" if name.indexOf('/', 1) is -1
  
  error = (msg) ->
    console.log "Save of #{name} failed: #{msg}"
    exchange.respond.error msg

  steps(
    ->  @on 'error', (msg) -> error(msg); @abort()
    ->  files.find "#{name}.html", @next (@filename) ->
    ->  if not @filename then @html = ''; @skip()
    ->  fs.readFile @filename, 'utf8', @next (@error, @html) ->
    ->  exchange.respond.read_request @next (@changes) ->
    ->  patch.apply @html, @changes, @next (@html) ->
    ->  throw "source differs from expected" if not @html
    ->  fs.writeFile @filename, @html, 'utf8', @next (@error) ->
    ->  exchange.response.end()
  )
