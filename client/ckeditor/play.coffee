# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
dirs = require 'dirs'

module.exports = (exchange) ->
  exchange.respond.client ->
    CKEDITOR.plugins.add 'play',
      icons: 'play',
      init: (editor) ->
        editor.addCommand 'play', exec: (editor) ->
          caret = usdlc.page_editor.getSelection().getRanges()[0].startContainer
          for parent in caret.getParents(true)
            break if parent.getAttribute?('id') is 'document'
            owner = parent
          start = $(owner.$)
          if not start.is('h1,h2,h3,h4,h5,h6')
            start = start.prevAll('h1,h2,h3,h4,h5,h6').first()
          level = +start.prop("tagName")[1] ? 1
          path = [start.text()]
          start.prevAll('h1,h2,h3,h4,h5,h6').each ->
            parent = $(this)
            if (parent_level = +parent.prop("tagName")[1]) < level
              level = parent_level
              return path.unshift parent.text()
            else
              return false  # found root
          doc = localStorage.url.split('#')[0]
          steps(
            ->  @requires 'querystring'
            ->  # now we have querystring use it
                url = "/server/http/gwt.coffee?" + @querystring.stringify
                  project:  roaster.environment.projects[localStorage.project]
                  document: doc
                  sections: ".*/#{path.join('/')}(/.*)*$".replace(/\s/g, '_')
                xhr = $.get url, (data, status, xhr) ->
                xhr.fail -> roaster.message "<b>GWT Failed to run</b>"
          )
        editor.ui.addButton 'play',
          label: 'Play instrumentation in this section'
          command: 'play'
          toolbar: 'uSDLC'
