# Copyright (C) 2012,13 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license
http = require 'http'
querystring = require 'querystring'
url = require 'url'
counter = 0

# process the command line
args = querystring.parse(process.argv[2..-1].join('&'), '&')
port = args.port ? 9009
user = args.user ? 'Administrator'

# create a server ready to listen
server = http.createServer (request, response) ->
  try
    console.log request.url
    href = url.parse request.url, true
    switch request.method
      when 'GET' # sends static files to the browser
        response.writeHead 200, {'Content-Type': 'text/plain'}
        response.end "#{counter++}"
      when 'POST' # is used to run instrumentation with data
        a = 1
      when 'PUT' # is used to save pages back to the file system
        a = 1
  catch error
    console.log error
    
server.listen port

console.log """
usage: go server port=#{port} user=#{user}

uSDLC running on http://localhost:#{port}

"""