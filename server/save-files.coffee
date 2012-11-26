# Copyright (C) 2012,13 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license
fs = require 'fs'; url = require 'url', path = require 'path'

module.exports = (request, response) ->
  name = path.join './', url.parse(request.url).pathname
  file = fs.createWriteStream(name)
  request.on 'data', (data) -> file.write(data)
  request.on 'end', ->
    file.end()
    response.writeHead(200)
    response.end()