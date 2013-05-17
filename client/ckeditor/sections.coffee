# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
module.exports = (exchange) ->
  exchange.respond.client ->
    spaces = "              "
    usdlc.richCombo
      name: 'sections'
      label: 'Sections'
      toolbar: 'usdlc,3'
      className: 'section_list'
      no_create: true
      items: (next) ->
        sections = []
        $(usdlc.page_editor.getData()).filter('h1,h2,h3,h4,h5,h6').each ->
          level = @nodeName[1]
          sections.push(
            "#{@innerHTML}|<pre>#{spaces[1..level*2]}#{@innerHTML}</pre>")
        next sections
      selected: -> usdlc.current_section()
      select: (value) -> usdlc.goto_section value