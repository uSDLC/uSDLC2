# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
fs = require 'fs'; dirs = require 'dirs'; steps = require 'steps'
path = require 'path'

#exclude=^ext$|^ext/.*|^gen$|^gen/.*|^usdlc$|^usdlc/.*

module.exports = (exchange) ->
  project = dirs.projects[exchange.request.url.query.project]
  list = {}

  include = exchange.request.url.query.include
  exclude = exchange.request.url.query.exclude
  if include and exclude
    include = new RegExp(include)
    exclude = new RegExp(exclude)
    excluded = (file_path) -> exclude.test(file_path) and not include.test(file_path)
  else if include
    include = new RegExp(include)
    excluded = (file_path) -> not include.test(file_path)
  else if exclude
    exclude = new RegExp(exclude)
    excluded = (file_path) -> exclude.test(file_path)
  else
    excluded = (file_path) -> false

  read_dir = (from, list, dir_read) ->
    process_file = (file, next) ->
      file_path = path.join(from, file)
      return next() if file[0] is '.' or excluded(file_path)
      fs.lstat file_path,  (error, stats) ->
        return next(error) if error
        if stats.isDirectory()
          read_dir file_path, list[file] = {}, next
        else # ordinary file
          list[file] = true
          next()
    steps(
      # ->  @on 'error', (err) -> @abort()
      ->  fs.readdir from, @next (@error, @files) ->
      ->  @list @files..., process_file
      ->  dir_read()
    )

  read_dir project, list, -> exchange.respond.json list
