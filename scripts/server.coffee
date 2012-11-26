# Copyright (C) 2012,13 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license
http = require 'http'; querystring = require 'querystring'; url = require 'url'
serve = require 'serve-files'; save = require 'save-files'

# process the command line
args = querystring.parse(process.argv[2..].join('&'))
port = args.port ? 9009
user = args.user ? 'Administrator'
debug_mode = args.debug

if debug_mode
  # in debug mode we allow an exception to kill the server - with a stack trace
  service_request = (action) -> action()
else
  # while for production we just log the message and go for a new request
  service_request = (action) ->
    try
      action()
    catch error
      console.log error

# create a server ready to listen
server = http.createServer (request, response) ->
  service_request ->
    console.log request.url
    request.url = url.parse request.url
    switch request.method
      # GET runs /uSDLC2/server/actor/client/#{ext}.coffee
      when 'GET' then serve(request, response, 'client')
      # PUT writes body to disk to a file that matches the URL
      when 'PUT' then save(request, response)
      # GET runs /uSDLC2/server/actor/server/#{ext}.coffee
      when 'POST' serve(request, response, 'server')
      # Oops - some command we aren't dealing with
      else
        response.writeHead(500); response.end()
        console.log "Unhandled request type: #{request.method}"
    
server.listen port

console.log """
usage: go server port=#{port} user=#{user}

uSDLC running on http://localhost:#{port}

"""