# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
fs = require "file-system", line_reader = require "line_reader"
path = require 'path'

# projects to check for as part of a file path
projects = { uSDLC2 : '.' }

# add a new project both to the file and in reference
fs.add_project = (project_name, project_path) ->
  project_path = path.relative fs.base(), project_path
  projects[project_name] = project_path
  fs.appendFile 'ext/projects.ini', "#{project_name}=#{project_path}"

module.exports = (environment) ->
  require(fs.node('/config/base'))(environment)

# over-ride fs.find() to search other projects
base_find = fs.find

# this one is used all the time to look for paths in projects
roaster_find = (name, next) ->
  [project, rest] = name.split /^\/?(.*?)\/(.*)$/
  if project of projects
    next(fs.base(projects[project], rest))
  else
    base_find name, next

# this one is run once to load projects from disk
fs.find = (name, next) ->
  fs.find = roaster_find
  reader = line_reader.for_file fs.base('ext/projects.ini'), (line) ->
    return if line.length is 0 or line[0] is '#'
    [project_name, project_path] = line.split '='
    projects[project_name] = project_path
  reader.on 'end', -> fs.find name, next
