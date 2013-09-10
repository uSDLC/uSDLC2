# Copyright (C) 2013 paul@marrington.net, see GPL for license

class Metadata
  constructor: (@options) -> # name, label, css
    @options.label ?= @options.name
    @options.class ?= @options.name
  fetch: (group_name, item_name, builder) ->
    el = usdlc.section_element null, "div.#{group_name}", ->
      return $('<div>').addClass("metadata #{group_name}").
          html("#{group_name}: ")
    name = item_name.split('.')[0]
    if not (item = $("span.#{name}", el)).length
      item = $('<span>').addClass(name).appendTo(el)
      builder(item)
    return [el, item]
    
# item name, url
class Links extends Metadata
  update: (options) ->
    @fetch @options.name, options.name, (item) ->
      item.html "<a href=\"#{options.url}\">"+
        "#{options.name}</a>"
  
types = { Links }
instances = {}

module.exports =
  initialise: (next) ->
    next()
  define: (options) -> # name, label, css, type
    instance = new types[options.type](options)
    return (options) -> instance.update(options)
  add_bridge_and_play_ref: ->
    ref = @define name: 'Ref', type: 'Links'
    ref
      name: 'Bridge'
      url: "javascript:usdlc.bridge_editor()"
    ref
      name: 'Play'
      url: "javascript:usdlc.play()"
