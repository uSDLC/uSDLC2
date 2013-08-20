# Copyright (C) 2013 paul@marrington.net, see GPL for license
fs = require 'fs'; dirs = require 'dirs'
steps = require 'steps'; path = require 'path'

module.exports = (exchange) ->
  project = exchange.request.url.query.project
  project = dirs.projects[project].base
  type = exchange.request.url.query.type
  list = []

  include = exchange.request.url.query.include
  exclude = exchange.request.url.query.exclude
  if include and exclude
    include = new RegExp(include)
    exclude = new RegExp(exclude)
    excluded = (file_path) ->
      exclude.test(file_path) and not include.test(file_path)
  else if include
    include = new RegExp(include)
    excluded = (file_path) -> not include.test(file_path)
  else if exclude
    exclude = new RegExp(exclude)
    excluded = (file_path) -> exclude.test(file_path)
  else
    excluded = (file_path) -> false

  read_dir = (from, dir_read, processor) ->
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

  send_json = -> exchange.respond.json list
  send_html = -> exchange.respond.html list...

  json_list = (from, list, dir_read) ->
    read_dir from, dir_read,
    (file, file_path, stats, next) ->
      category = from.split('/')[-1..-1][0]
      list.push(item =
        name: file
        category: category
        path: file_path)
      if stats.isDirectory()
        json_list file_path, item.children = [], next
      else # ordinary file
        next()
  
  html_item = (before, file, file_path, after) ->
    list.push before
    list.push "<a href='", file_path, "'>", file, "</a>"
    list.push after
  
  html_list = (from, dir_read) ->
    read_dir from, dir_read,
    (file, file_path, stats, next) ->
      if stats.isDirectory()
        html_item "<li>", file_path, file, "<ul>"
        html_list file_path, ->
          list.push '</ul></li>\n'
          next()
      else # ordinary file
        html_item "<li>", file_path, file, "</li>\n"
        next()

  grep_list = (project_dir, pattern) ->
    pattern = new regExp pattern
    grep = (from, list) ->
      read_dir from, send_json,
      (file, file_path, stats, next) ->
        if stats.isDirectory()
          grep file_path, list[file] = {}, next
        else # ordinary file
          # TODO: only add if pattern in file
          list[file] = file_path
          next()
    grep(project_dir, list)

  autocomplete_list = (from, list, dir_read) ->
    read_dir from, dir_read,
    (file, file_path, stats, next) ->
      if stats.isDirectory()
        autocomplete_list file_path, list, next
      else # ordinary file
        category = from.split('/')[-1..-1][0]
        list.push
          label: file
          path: "#{from}/#{file}"
          category: category
        next()

  switch type
    when 'autocomplete'
      autocomplete_list project, list, send_json
    when 'html'
      html_list project, send_html
    when 'grep'
      pattern = exchange.request.url.query.pattern
      grep_list project, inclue, exclude, pattern
    else # 'json'
      json_list project, list, send_json
