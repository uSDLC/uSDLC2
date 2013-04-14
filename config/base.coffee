# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
fs = require "fs", line_reader = require "line_reader"
path = require 'path'; files = require "files"; dirs = require 'dirs'

# projects to check for as part of a file path
projects = { uSDLC2 : '.' }

# add a new project both to the file and in reference
dirs.add_project = (project_name, project_path) ->
  project_path = path.relative dirs.base(), project_path
  projects[project_name] = project_path
  fs.appendFile 'ext/projects.ini', "#{project_name}=#{project_path}\n"

module.exports = (environment) ->
  require(dirs.node('/config/base'))(environment)

# over-ride files.find() to search other projects
base_find = files.find

# this one is used all the time to look for paths in projects
roaster_find = (name, next) ->
  [project, rest] = name.split /^\/?(.*?)\/(.*)$/
  if project of projects
    next(dirs.base(projects[project], rest))
  else
    base_find name, next

# this one is run once to load projects from disk
files.find = (name, next) ->
  files.find = roaster_find
  reader = line_reader.for_file dirs.base('ext/projects.ini'), (line) ->
    return if line.length is 0 or line[0] is '#'
    [project_name, project_path] = line.split '='
    projects[project_name] = project_path
  reader.on 'end', -> files.find name, next
