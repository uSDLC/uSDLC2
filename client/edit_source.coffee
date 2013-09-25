# Copyright (C) 2013 paul@marrington.net, see /GPL for license
ref = null

# item.value item.path item.category
usdlc.edit_source = (item) -> queue ->
  item.key = item.path.replace /[\.\/]/g, '_'
  params = "filename=#{item.path}&seed=#{usdlc.seed++}"
  
  @requires '/client/codemirror/editor.coffee', ->
  
  @data "/server/http/read.coffee?#{params}", ->
    parts = item.value.split('.')
    attr = -> parts[parts.length - 1]
    text = (value) =>
      if value
        usdlc.save item.path, item.key, value
      else
        return sessionStorage[item.key] = @read

    @editor
      name:     item.key
      title:    "#{item.value} - #{item.category}"
      fix_height_to_window: 20
      source:   { attr, text }
      position:
        my: "right top+10", at: "right-10 top", of: window

    item_data = "{value:'#{item.value}'," +
      "path:'#{item.path}',category:'#{item.category}'}"
    path = "javascript:usdlc.edit_source(#{item_data})"
    ref name: item.value, url: path
    @next()

module.exports.initialise = (next) -> queue ->
  @requires '/client/ckeditor/metadata.coffee', ->
    ref = @metadata.define name: 'Ref', type: 'Links'
    next()
