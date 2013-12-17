# Copyright (C) 2013 paul@marrington.net, see GPL for license
fs = require 'fs'; patch = require 'common/patch'
files = require 'files'

module.exports = (exchange) ->
  name = exchange.request.url.query.name

  error = (msg) ->
    console.log "Save of #{name} failed: #{msg}"
    exchange.respond.error msg

  boom = (filename) ->
    throw new Error(
      "source differs from expected for #{filename}")

  files.find name, (filename) ->
    return if not filename
    fs.readFile filename, 'utf8', (err, html) ->
      return error(err.message) if err
      exchange.respond.read_request (changes) ->
        patch.apply html ? '', changes, (html) ->
          boom(filename) if not html
          fs.writeFile filename, html, 'utf8', (err) ->
            exchange.response.end()
