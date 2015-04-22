# Copyright (C) 2015 paul@marrington.net, see /GPL license
dirs = require('dirs');   path = require('path')
files = require('files'); fs = require('fs')

module.exports = (project_path, next) ->
  error = err = false          
  copy = (sources..., destination, copied) -> do next_copy = (err) ->
    return copied(error = err) if err
    return copied() if not sources.length
    name = sources.pop()
    from = "templates/project/#{name}"
    to = path.join(project_path, destination, name)
    files.copy(from, to, next_copy);

  dirs.mkdirs path.join(project_path, "usdlc2"), ->
    copy "usdlc2.css", "usdlc2.js", "usdlc2", ->
      copy "usdlc2.html", "", ->
        index = path.join(project_path, "usdlc2", "index.html")
        if not fs.exists(index)
          copy "index.html", "usdlc2", -> next(error)