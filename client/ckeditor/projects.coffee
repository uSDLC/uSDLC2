# Copyright (C) 2013 paul@marrington.net, see /GPL for license
dirs = require 'dirs'; files = require 'files'
fs = require 'fs'

module.exports = (exchange) ->
  # request to server
  query = exchange.request.url.query
  if query.load
    dirs.project_reader (projects) ->
      exchange.respond.json projects
    return
  if query.add
    project_path = "../#{query.path}"
    usdlc2_path = "../#{project_path}/usdlc2"
    files.is_dir usdlc2_path, (err, is_dir) ->
      dirs.mkdirs usdlc2_path, ->
        files.copy 'usdlc2/document.css',
        "#{usdlc2_path}/document.css", (err) ->
          dirs.add_project(query.add, base: project_path)
          exchange.respond.json error: err
    return
    
  # code run on client
  exchange.respond.client ->
    order = roaster.ckeditor.tools.projects
    usdlc.richCombo
      name: 'projects'
      label: 'Projects'
      toolbar: "uSDLC,#{order[0]}"
      items: (next) ->
        roaster.request.json "/client/ckeditor/projects.coffee?load=true",
        (projects) ->
          roaster.environment.projects =@projects
          next (key.replace(/_/g, ' ')\
            for key, value of projects).sort()
      selected: -> usdlc.project.replace /_/g, ' '
      select: (value) ->
        if value is 'create'
          roaster.client '/client/ckeditor/create_project.coffee',
          (create_project) -> create_project()
        else
          usdlc.setProject value.replace(/\s/g, '_')
          page = usdlc.projectStorage('url') ? 'Index'
          usdlc.edit_page page
