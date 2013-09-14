# Copyright (C) 2013 paul@marrington.net, see GPL for license
path = require 'path'; fs = require 'fs'
_ = require 'underscore'

module.exports = (exchange) ->
  # request to server
  if project = exchange.request.url.query.project
    projects = exchange.environment.projects
    usdlc2_path = path.join projects[project].base, 'usdlc2'
    fs.readdir usdlc2_path, (err, documents) ->
      exchange.respond.json (path.basename(name, '.html') \
        for name in documents \
          when path.extname(name) is '.html').sort()
    return
  # code run on client
  exchange.respond.client ->
    usdlc.richCombo
      name: 'documents'
      label: 'Documents'
      toolbar: 'uSDLC,2'
      items: (next) -> queue ->
        url = "/client/ckeditor/documents.coffee"+
              "?project=#{usdlc.project}"
        @json url, ->
          next (name.replace(/_/g, ' ')\
            for name in @documents).sort()
      selected: ->
        usdlc.projectStorage('document').replace /_/g, ' '
      select: (value) ->
        value = 'Index' if value is 'create'
        usdlc.edit_page value.replace(/\s/g, '_')
