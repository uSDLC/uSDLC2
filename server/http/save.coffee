# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
fs = require 'fs'; patch = require 'common/patch'
files = require 'files'; steps = require 'steps'

module.exports = (exchange) ->
  name = exchange.request.url.query.name
  name += "/Index" if name.indexOf('/', 1) is -1
  try
    steps(
      ->  files.find "#{name}.html", @next (@filename) ->
      ->  if not @filename then @html = ''; @skip()
      ->  fs.readFile @filename, 'utf8', @next (@error, @html) ->
      ->  exchange.respond.read_request @next (@changes) ->
      ->  patch.apply @html, @changes, @next (@html) ->
      ->  fs.writeFile @filename, @html, 'utf8', @next (@error) ->
      ->  exchange.response.end()
    )
  catch err
    console.log msg = "Save of #{name} failed: #{err}"
    exchange.respond.error msg
