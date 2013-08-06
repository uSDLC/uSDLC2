# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
fs = require 'fs'; patch = require 'common/patch'
files = require 'files'; steps = require 'steps'

module.exports = (exchange) ->
  name = exchange.request.url.query.name

  error = (msg) ->
    console.log "Save of #{name} failed: #{msg}"
    exchange.respond.error msg

  boom = (filename) ->
    throw new Error(
      "source differs from expected for #{filename}")

  steps(
    ->  @on 'error', (msg) -> error(msg); @abort()
    ->  files.find name, @next (@filename) ->
    ->  if not @filename then @html = ''; @skip()
    ->  fs.readFile @filename, 'utf8', @next (@error, @html) ->
      # this turns to streams 1
    ->  exchange.respond.read_request @next (@changes) ->
    ->  patch.apply @html, @changes, @next (@html) ->
    ->  boom(@filename) if not @html
    ->  fs.writeFile @filename, @html, 'utf8', @next (@error) ->
    ->  exchange.response.end()
  )
