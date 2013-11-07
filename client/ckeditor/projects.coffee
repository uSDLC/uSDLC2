# Copyright (C) 2013 paul@marrington.net, see /GPL for license
dirs = require 'dirs'

module.exports = (exchange) ->
  # request to server
  if project = exchange.request.url.query.load
    dirs.project_reader (projects) ->
      exchange.respond.json projects
    return
    
  # code run on client
  exchange.respond.client ->
    order = roaster.ckeditor.tools.projects
    usdlc.richCombo
      name: 'projects'
      label: 'Projects'
      toolbar: "uSDLC,#{order[0]}"
      items: (next) -> queue ->
        @json "/client/ckeditor/projects.coffee?load=true", ->
          roaster.environment.projects = @projects
          next (key.replace(/_/g, ' ')\
            for key, value of @projects).sort()
      selected: -> usdlc.project.replace /_/g, ' '
      select: (value) ->
        if value is 'create'
          queue ->
            @requires '/client/ckeditor/create_project.coffee',
              @next -> @create_project()
        else
          usdlc.setProject value.replace(/\s/g, '_')
          page = usdlc.projectStorage('url') ? 'Index'
          usdlc.edit_page page
