# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
fs = require "fs", line_reader = require "line_reader"
path = require 'path'; files = require "files"; dirs = require 'dirs'

# projects to check for as part of a file path
projects = { uSDLC2 : '.' }

# add a new project both to the file and in reference
dirs.add_project = (project_name, project_path) ->
  project_path = path.relative dirs.base(), project_path
  projects[project_name] = project_path
  fs.appendFile 'local/projects.ini', "#{project_name}=#{project_path}\n"

module.exports = (environment) ->
  require(dirs.node('/config/base'))(environment)
  environment.projects = projects

# over-ride files.find() to search other projects
base_find = files.find

# this one is used all the time to look for paths in projects
roaster_find = (name, next) ->
  [all, project, rest] = name.split /^\/?(.*?)\/(.*)$/
  if project of projects
    next(dirs.base(projects[project], 'usdlc2', rest))
  else
    base_find name, next

# this one is run once to load projects from disk
files.find = (name, next) ->
  files.find = roaster_find
  reader = line_reader.for_file dirs.base('local/projects.ini'), (line) ->
    return if line.length is 0 or line[0] is '#'
    [project_name, project_path] = line.split '='
    projects[project_name] = project_path
  reader.on 'end', -> files.find name, next

# add a http request processor to capture project/document pages
global.http_processors.unshift (exchange, next_processor) ->
  files.find_in_project exchange.request.url.pathname[1..], (filename) ->
    return next_processor() if not filename
    if exchange.request.url.query.edit?
      # we want to edit, load editor and let it reload project/page
      exchange.request.url.pathname = '/'
      next_processor()
    else
      # send it off as a static file
      exchange.request.filename = filename
      exchange.respond.send_static -> # service ends here

# Assume file starts with name of project...
files.find_in_project = (name, next) ->
  # break up into project/page pattern
  page = 'Index'; project = name
  if (slash = project.indexOf('/')) isnt -1
    page = project[slash+1..]
    project = project[0...slash]
  return next() if not projects[project] # see if it is a valid project
  # if we can't find the file look for a template of the same name (or default)
  paths = [
    path.join projects[project], "usdlc2/#{page}.html"
    path.join projects[project], "usdlc2/templates/#{page}.html"
    dirs.base "local/templates/#{page}.html"
    dirs.base "templates/#{page}.html"
    path.join projects[project], "usdlc2/templates/default.html"
    dirs.base "local/templates/default.html"
    dirs.base "templates/default.html"
  ]
  do finder = ->
    return next() if not paths.length # this service failed to work
    filename = paths.shift()
    fs.exists filename, (exists) ->
      return finder() if not exists
      next(filename)
