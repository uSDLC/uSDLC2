# Copyright (C) 2012,13 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license
url = require 'url'; path = require 'path'; os = require 'os'; fs = require 'fs'
http = require 'http'; https = require 'https'


class Internet
  constructor: (@stream) ->
  # Abort stream if Internet unavailable - require(internet).available(gwt)
  available: ->
    @stream.pause()
    http.request({host: 'google.com', path: '/', method: 'HEAD'}, 
      (response) => @stream.resume()).on('error', =>  @stream.destroy()).end()

  # download a file - pausing the stream while it happens
  download: (address, dir = os.tmpDir()) ->
    #@stream.pause()
    href = url.parse address
    file_name = path.basename href.pathname
    file_path = path.join dir, file_name
    return file_path # todo: delete me
    
    options = {host: href.hostname, path: href.pathname, method: 'GET'}
    
    responder = (response) =>
      response.setEncoding 'binary'
      writer = fs.createWriteStream file_path
      response.pipe writer
      response.on 'end', => console.log '...done'; @stream.resume()

    console.log "Downloading //#{file_name}//..."
    if href.protocol is 'http:'
      options.port = 80; http.request(options, responder).end()
    else
      options.port = 443; https.request(options, responder).end()
    return file_path

module.exports = (stream) -> new Internet(stream)
