# Copyright (C) 2013 paul@marrington.net, see GPL for license
module.exports = -> roaster.preload "/client/autocomplete.coffee",
  "/client/edit_source.coffee", (autocomplete, edit_source) ->
    do module.exports = ->
      project = roaster.environment.projects[usdlc.project]
      path = "/server/http/files.coffee"
      exclude = project.exclude ? ''
      include = project.include ? ''
      selector = "exclude=#{exclude}&include=#{include}"
      args = "project=#{usdlc.project}&type=autocomplete"
      
      roaster.request.json "#{path}?#{args}&#{selector}", (data) ->
        autocomplete
          title: 'File...'
          source: data
          select: (filename) -> edit_source filename
