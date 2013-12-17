# Copyright (C) 2013 paul@marrington.net, see /GPL for license
path = require 'path'
ref = editor = metadata = null

# item.value item.path item.category
usdlc.edit_source = (item) ->
  item.key = item.path.replace /[\.\/]/g, '_'
  parts = item.value.split('.')
  attr = -> parts[parts.length - 1]
  contents = ''
  params = "filename=#{item.path}&seed=#{usdlc.seed++}"
  
  read_contents = (next) ->
    roaster.request.data "/server/http/read.coffee?#{params}", (err, contents) ->
      sessionStorage[item.key] = contents
      return next(contents) if contents.length
      type = path.extname(item.path).substring(1)
      template = "/client/templates/#{type}_template.coffee"
      roaster.clients template, (template_retriever) ->
        next(template_retriever?() ? '')
  
  read_contents (contents) ->
    text = (value) =>
      if value
        usdlc.save item.path, item.key, contents = value
      else
        return contents

    editor
      name:     item.key
      title:    "#{item.value} - #{item.category}"
      source:   { attr, text }

    item_data = "{value:'#{item.value}'," +
      "path:'#{item.path}',category:'#{item.category}'}"
    url = "javascript:usdlc.edit_source(#{item_data})"
    ref name: item.value, url: url

module.exports.initialise = (next) ->
  roaster.clients "/client/codemirror/editor.coffee",
    "/client/ckeditor/metadata.coffee", (args...) ->
      [editor, metadata] = args
      ref = metadata.define name: 'Ref', type: 'Links'
      next()
