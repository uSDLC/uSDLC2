# Copyright (C) 2013 paul@marrington.net, see GPL for license
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
    ->  if not @filename then @skip()
    ->  fs.readFile @filename, 'utf8', @next (@err, @html) ->
      # this turns to streams 1
    ->  exchange.respond.read_request @next (@changes) ->
    ->  patch.apply @html ? '', @changes, @next (@html) ->
    ->  boom(@filename) if not @html
    ->  fs.writeFile @filename, @html, 'utf8', @next (@error) ->
    ->  exchange.response.end()
  )
###
# Copyright (C) 2013 paul@marrington.net, see GPL for license
patch = require 'common/patch'
files = require 'files'; queue = require('steps').queue

module.exports = (exchange) -> queue ->
  name = exchange.request.url.query.name
  @on 'error', (msg) ->
    console.log "Save of #{name} failed: #{msg}"
    exchange.respond.error msg
    @abort()
    
  @files.find name, @next (@filename) ->
    if @filename
      @files.read(@filename, 'utf8', @next (@error, @html) ->)
  @mixin exchange.respond
  @respond.read_request @next (@changes) ->
  @patch.apply @html ? '', @changes, @next (@html) ->
    if not @html?.length then throw new Error(
      "source differs from expected for #{filename}")
  @files.write name, @html, 'utf8', @next (@error) ->
    exchange.response.end()
###
