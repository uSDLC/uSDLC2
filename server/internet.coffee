# Copyright (C) 2012,13 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license
url = require 'url'; path = require 'path'; os = require 'os'; fs = require 'fs'
http = require 'http'; https = require 'https'


class Internet
  constructor: (@gwt) ->
    # download a file - pausing the stream while it happens
    @download =
      from: (@from, next = (last) -> last()) => @download_now(next) if @to; return @download
      to: (@to, next = (last) -> last()) => @download_now(next) if @from; return @download
  # Abort stream if Internet unavailable - require(internet).available(gwt)
  available: ->
    @gwt.pause()
    http.request({host: 'google.com', path: '/', method: 'HEAD'}, 
      (response) => @gwt.resume()).on('error', =>  @gwt.skip.section()).end()
    
  download_now: (next) ->
    @gwt.pause()
    href = url.parse @from
    file_name = path.basename href.pathname
    file_path = "#{@to}"
    
    options = {host: href.hostname, path: href.pathname, method: 'GET'}
    
    responder = (response) =>
      response.setEncoding 'binary'
      writer = fs.createWriteStream file_path
      response.pipe writer
      response.on 'end', => console.log '...done'; next(=> @gwt.resume())

    console.log "Downloading //#{file_name}//..."
    if href.protocol is 'http:'
      options.port = 80; http.request(options, responder).end()
    else
      options.port = 443; https.request(options, responder).end()
    @from = @to = ''
    return file_path

module.exports = (stream) -> new Internet(stream)
