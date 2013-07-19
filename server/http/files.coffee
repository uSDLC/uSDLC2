# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
fs = require 'fs'; dirs = require 'dirs'; steps = require 'steps'
path = require 'path'

module.exports = (exchange) ->
  project = dirs.projects[exchange.request.url.query.project]
  include = exchange.request.url.query.include
  exclude = exchange.request.url.query.exclude
  list = {}

  read_dir = (from, list, dir_read) ->
    process_file = (file, next) ->
      return next() if file[0] is '.'
      file_path = path.join(from, file)
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
