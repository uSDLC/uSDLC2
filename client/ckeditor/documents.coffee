# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
path = require 'path'; fs = require 'fs'; _ = require 'underscore'

module.exports = (exchange) ->
  # request to server
  if project = exchange.request.url.query.project
    usdlc2_path = path.join exchange.environment.projects[project], 'usdlc2'
    fs.readdir usdlc2_path, (err, documents) ->
      exchange.respond.json (path.basename(name, '.html') \
        for name in documents when path.extname(name) is '.html').sort()
    return
  # code run on client
  exchange.respond.client ->
    usdlc.richCombo
      name: 'documents'
      label: 'Documents'
      toolbar: 'usdlc,2'
      items: (next) ->
        url = "/client/ckeditor/documents.coffee?project=#{localStorage.project}"
        steps(
          ->  @json url
          ->  next @documents.sort()
        )
      selected: -> localStorage.document.replace /_/g, ' '
      select: (value) ->
        if value is 'create'
          alert("Under Construction")
        else
          usdlc.edit_page value.replace(/\s/g, '_')
