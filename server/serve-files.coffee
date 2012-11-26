# Copyright (C) 2012,13 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license
send = require 'send'; url = require 'url'; actors = {client:{}, server:{}}

module.exports = (request, response, domain) ->
  send_static = (request, response) ->
    # by default we send it as static content where the browser caches it forever
    href = ".#{request.url.pathname}"
    send(request, href).maxage(Infinity).pipe(response)
    
  # use the file extension to see how to deal with this file
  ext = ''
  path = request.url.pathname
  dot = path.lastIndexOf '.'
  if dot is -1
    request.url.pathname = '/uSDLC2/client/index.html' if path is '/'
  else
    ext = path[dot + 1..-1]
  actor = actors[domain][ext]

  # we haven't come across this file type before, see if we can acquire the matching actor
  if not actor
    try
      actor = require "actor/#{domain}/#{ext}"
    catch error
      actor = send_static # default to cached send if no special handling requested
    actors[domain][ext] = actor
  
  # all the set up is done, process the request
  actor(request, response)
