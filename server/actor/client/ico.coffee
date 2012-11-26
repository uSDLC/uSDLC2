# Copyright (C) 2012,13 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license
send = require 'send'

modules.export = (request, response) ->
  url = request.url.pathname
  url = '/uSDLC2/client/favicon.ico' if url is '/favicon.ico'
  send(request, url).maxage(Infinity).pipe(response)