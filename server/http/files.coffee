# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
fs = require 'fs'; dirs = require 'dirs'; steps = require 'steps'
path = require 'path'

module.exports = (exchange) ->
  project = dirs.projects[exchange.request.url.query.project].base
  type = exchange.request.url.query.type
  list = null

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

  read_dir = (from, list, dir_read, processor) ->
    process_file = (file, next) ->
      file_path = path.join(from, file)
      return next() if file[0] is '.' or excluded(file_path)
      fs.lstat file_path,  (error, stats) ->
        return next(error) if error
        processor file, file_path, stats, next
    steps(
      ->  fs.readdir from, @next (@error, @files) ->
      ->  @list @files..., process_file
      ->  dir_read()
    )

  json_list = (from, list, dir_read) ->
    read_dir from, list, dir_read, (file, file_path, stats, next) ->
      if stats.isDirectory()
        json_list file_path, list[file] = {}, next
      else # ordinary file
        list[file] = file_path
        next()

  autocomplete_list = (from, list, dir_read) ->
    read_dir from, list, dir_read, (file, file_path, stats, next) ->
      if stats.isDirectory()
        autocomplete_list file_path, list, next
      else # ordinary file
        category = from.split('/')[-1..-1][0]
        list.push label: file, path: "#{from}/#{file}", category: category
        next()

  send_json = -> exchange.respond.json list
  switch type
    when 'autocomplete'
      list = []
      autocomplete_list project, list, send_json
    else # 'json'
      list = {}
      json_list project, list, send_json
