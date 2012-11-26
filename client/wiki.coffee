# Copyright (C) 2012,13 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license

# Usage: $('#element').wiki2html()
->
  wiki_plugin = ($) ->
    $.fn.extend
      wiki2html: ->

        # lists need to be done using a function to allow for recusive calls
        list = (str) ->
          return str.replace /(?:(?:(?:^|\n)[\*#].*)+)/g, (m) -> # (?=[\*#])
            type = if m.match(/(^|\n)#/) then 'OL' else 'UL'
            // strip first layer of list
            m = m.replace(/(^|\n)[\*#][ ]{0,1}/g, '$1');
            m = list(m);
            items = m.replace(/^\n/, '').split(/\n/).join('</li><li>')
            return "<#{type}><li>#{items}</li></#{type}>"
        
        @html list @text().
          replace(/(?:^|\n+)([^# =\*<].+)(?:\n+|$)/gm, (m, l) -> # paragraph
            return l if l.match(/^\^+$/)
            return "\n<p>#{l}</p>\n").
          replace(/(?:^|\n)[ ]{2}(.*)+/g, (m, l) -> # blockquotes
            return m if l.match(/^\s+$/))
            return "<blockquote>#{l}</blockquote>").
          replace(/((?:^|\n)[ ]+.*)+/g, (m) -> # code
            return m if m.match(/^\s+$/)
            return "<pre>#{m.replace(/(^|\n)[ ]+/g, "$1")}</pre>").
          replace(/(?:^|\n)([=]+)(.*)\1/g, (m, l, t) -> # headings
            return "<h#{l.length}>#{t}</h#{l.length}>").
          replace(/'''(.*?)'''/g, (m, l) -> # bold
            return "<strong>#{l}</strong>").
          replace(/''(.*?)''/g, (m, l) -> # italic
            return "<em>#{l}</em>").
          replace(/[^\[](http[^\[\s]*)/g, (m, l) -> # normal link
            return "<a href='#{l}'>#{l}</a>").
          replace(/[\[](http.*)[!\]]/g, (m, l) -> # external link
            p = l.replace(/[\[\]]/g, '').split(/ /)
            link = p.shift()
            p = if p.length then p.join(' ') else link
            return "<a href='#{link}'>#{p}</a>").
          replace(/\[\[(.*?)\]\]/g, (m, l) # internal link or image
            p = l.split(/\|/)
            var link = p.shift();
            p = p.length ? p.join('|') : link
            return "<a href='#{link}'>#{p}</a>")
       
  wiki_plugin(jQuery)