# Copyright (C) 2013 paul@marrington.net, see GPL for license
fs = require 'fs'; dirs = require 'dirs'; fs = require 'fs'
steps = require 'steps'; queue = steps.queue
files = require 'files'; path = require 'path'

module.exports = (exchange) ->
  query = exchange.request.url.query
  project = query.project
  project = dirs.projects[project]?.base
  
  errmsg = (what, error) ->
    e = false
    filename = path.basename query.path ? query.from
    e = "Can't #{what} '#{filename}'" if error
    return error: e
  
  switch query.cmd
    when 'rm' then queue ->
      @files.rm query.path, (error) ->
        exchange.respond.json errmsg 'delete', error
    when 'mv' then queue ->
      @files.mv query.from, query.to, (error) ->
        exchange.respond.json errmsg 'move', error
    when 'mk' then queue ->
      if query.path[0] is '~'
        console.log query.path[1..]
        query.path = dirs.projects[query.path[1..]].base
      @files.join query.path, query.name, (filename) ->
        fs.open filename, 'wx', (error, fd) ->
          fs.close fd, ->
          exchange.respond.json errmsg 'new', error
    else # ls
      type = query.type
      search = query.search
      re = new RegExp(query.re, 'm')
      list = []
    
      include = query.include
      exclude = query.exclude
      if include and exclude
        include = new RegExp(include)
        exclude = new RegExp(exclude)
        excluded = (file_path) ->
          return exclude.test(file_path) and
          not include.test(file_path)
      else if include
        include = new RegExp(include)
        excluded = (file_path) -> not include.test(file_path)
      else if exclude
        exclude = new RegExp(exclude)
        excluded = (file_path) -> exclude.test(file_path)
      else
        excluded = (file_path) -> false
      
      if search is 'grep'
        grep = (file, next) ->
          files.is_dir file, (error, is_dir) ->
            return next(true) if is_dir
            fs.readFile file, (err, contents) ->
              return next(false) if err
              return next(re.test(contents))
      else
        grep = (file, next) -> next(true)
    
      read_dir = (from, dir_read, processor) ->
        process_file = (file, next) ->
          file_path = path.join(from, file)
          if file[0] is '.' or excluded(file_path)
            return next()
          grep file_path, (found) ->
            return next() if not found
            fs.lstat file_path,  (error, stats) ->
              return next(error) if error
              processor file, file_path, stats, next
        steps(
          ->  @long_operation()
          ->  fs.readdir from, @next (@error, @files) ->
          ->  @list @files..., process_file
          ->  dir_read()
        )
    
      send_json = -> exchange.respond.json list
      send_html = -> exchange.respond.html list...
      add_node = (list, name, category, path) ->
        list.push item = {name, category, path}
        return item
      
      json_list = (from, list, dir_read) ->
        read_dir from, dir_read,
        (file, file_path, stats, next) ->
          category = from.split('/')[-1..-1][0]
          item = add_node list, file, category, file_path
          if stats.isDirectory()
            json_list file_path, item.children = [], next
          else # ordinary file
            next()
      
      doc_list = (sender) ->
        dirs.project_reader (projects) ->
          sorted = (project for project, data of projects)
          sorted.sort()
          do one_project = ->
            return sender() if not sorted.length
            project = sorted.shift()
            path_to_project = projects[project].path
            node = add_node project, '', path_to_project
            node.children = []
            fs.readdir path_to_project, (err, files) ->
              for file in files
                add_node node.children, file, project, file
              
      
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
        when 'docs'
          doc_list send_json
        else # 'json'
          json_list project, list, send_json
