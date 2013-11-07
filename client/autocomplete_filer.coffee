# Copyright (C) 2013 paul@marrington.net, see GPL for license

module.exports = -> queue ->
  project = roaster.environment.projects[usdlc.project]
  path = "/server/http/files.coffee"
  exclude = project.exclude ? ''
  include = project.include ? ''
  selector = "exclude=#{exclude}&include=#{include}"
  args = "project=#{usdlc.project}&type=autocomplete"
  
  @requires "/client/autocomplete.coffee",
    "/client/edit_source.coffee", @next ->
  @json "#{path}?#{args}&#{selector}", @next ->
    @autocomplete
      title: 'File...'
      source: @files
      select: (filename) -> @edit_source filename
