# Copyright (C) 2013 paul@marrington.net, see /GPL for license
fs = require "fs", line_reader = require "line_reader"
path = require 'path'; files = require "files"
dirs = require 'dirs'

# projects to check for as part of a file path
dirs.projects = projects =
  uSDLC2 :  base: '.'
  roaster : base: '../roaster'

# over-ride files.find() to search other projects
base_find = files.find
# this one is used all the time to look for paths in projects
# next(full_path, base_path, rest)
files.find = (name, next) ->
  [all, project, rest] = name.split /^\/?(.*?)\/(.*)$/
  if project of projects
    base = projects[project].base
    next(dirs.base(base, 'usdlc2', rest), base, rest)
  else
    base_find name, next
    
update_bases = ->
  dirs.bases = []
  for name, data of projects
    dirs.bases.push(path.resolve data.base)

# this one is run once to load projects from disk
do dirs.project_reader = (next = ->) ->
  list = {}
  line_reader.for_file 'local/projects.ini', (line) ->
    if not line?
      # now we have them all, atomic update
      dirs.projects = projects = list
      update_bases()
      if process.environment
        process.environment.projects = list
        process.environment.configuration.projects = list
      return next(projects)
    return if line.length is 0 or line[0] is '#'
    [project_name, options] = line.split '='
    options = options.split ','
    data = {}
    for option in options
      [key, value] = option.split ':'
      data[key] = value
    list[project_name] = data
    
dirs.add_project = (name, data) ->
  name = name.replace /\s+/g, '_'
  projects[name] = data
  serialised = []
  for name, data of projects
    serialised.push(name,'=')
    opts = []
    opts.push("#{k}:#{v}") for k,v of data
    serialised.push opts.join(','), '\n'
  dirs.mkdirs 'local', ->
    fs.writeFile 'local/projects.ini', serialised.join(''), ->
  update_bases()

# Assume file starts with name of project...
files.find_in_project = (name, next) ->
  # break up into project/page pattern
  page = 'Index'; project = name
  if (slash = project.indexOf('/')) isnt -1
    page = project[slash+1..]
    project = project[0...slash]
  # see if it is a valid project
  return next() if not projects[project]
  # if we can't find the file look for a template
  # of the same name (or default)
  base = projects[project].base
  paths = [
    path.join base, "usdlc2/#{page}.html"
    path.join base, "usdlc2/templates/#{page}.html"
    dirs.base "local/templates/#{page}.html"
    dirs.base "templates/#{page}.html"
    path.join base, "usdlc2/templates/default.html"
    dirs.base "local/templates/default.html"
    dirs.base "templates/default.html"
  ]
  do finder = ->
    return next() if not paths.length
    filename = paths.shift()
    fs.exists filename, (exists) ->
      return finder() if not exists
      next(filename)
