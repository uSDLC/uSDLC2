# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
fs = require "fs", line_reader = require "line_reader"
path = require 'path'; files = require "files"; dirs = require 'dirs'

# projects to check for as part of a file path
dirs.projects = projects = { uSDLC2 : '.' }

# add a new project both to the file and in reference
dirs.add_project = (project_name, project_path, record = true) ->
  return if projects[project_name] # already added
  dirs.bases.push path.resolve project_path
  project_path = path.relative dirs.base(), project_path
  projects[project_name] = project_path
  if record
    fs.appendFile 'local/projects.ini', "#{project_name}=#{project_path}\n"

# over-ride files.find() to search other projects
base_find = files.find
# this one is used all the time to look for paths in projects
# next(full_path, base_path, rest)
files.find = (name, next) ->
  [all, project, rest] = name.split /^\/?(.*?)\/(.*)$/
  if project of projects
    next(dirs.base(projects[project], 'usdlc2', rest), projects[project], rest)
  else
    base_find name, next

# this one is run once to load projects from disk
reader = line_reader.for_file 'local/projects.ini', (line) ->
  return if line.length is 0 or line[0] is '#'
  [project_name, project_path] = line.split '='
  dirs.add_project project_name, project_path, false

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