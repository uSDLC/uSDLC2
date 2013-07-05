# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
module.exports = (exchange) ->
  exchange.respond.client ->

    goto_section = (heading) ->
      usdlc.document.removeClass('outline')
      from = "#{window.location.pathname}?edit##{window.location.hash}"
      heading.scrollIntoView()
      document.body.scrollTop -= 60
      [pathname,hash] = localStorage.url.split('#')
      localStorage.url = "#{pathname}##{hash = heading.innerText}"
      history.pushState from, '', "#{pathname}?edit##{hash ? ''}"
      usdlc.document.blur()

    outline = ->
      listeners = []
      $('h1,h2,h3,h4,h5,h6').each ->
        heading = CKEDITOR.dom.element.get @
        listeners.push heading.on 'click', ->
          usdlc.document.children().show()
          usdlc.sources().hide()
          goto_section heading.$
          listener.removeListener() for listener in listeners
      usdlc.document.children().not('h1,h2,h3,h4,h5,h6').hide()
      usdlc.document.addClass('outline')

    CKEDITOR.plugins.add "sections",
      icons: 'sections',
      init: (editor) ->
        editor.addCommand 'sections', exec: (editor) -> outline()
        editor.ui.addButton 'sections',
          label: 'Document Sections',
          command: 'sections',
          toolbar: 'uSDLC'

    usdlc.goto_section = (name) ->
      sectionElements = {}
      $('h1,h2,h3,h4,h5,h6').each -> sectionElements[@innerHTML] = @
      return if not name or not sectionElements[name]
      goto_section sectionElements[name]

    usdlc.current_section = ->
      # window.location.hash[1..] if window.location.hash.length > 1
    scroll_timer = null
    set_hash = ->
      scroll_timer = null
      top = document.body.scrollTop; done = false
      $('h1,h2,h3,h4,h5,h6').each ->
        return if done
        section_top = $(@).offset().top
        if section_top > top
          window.location.hash = hash = @innerHTML
          localStorage.url = localStorage.url.split('#')[0] + "##{hash}"
          done = true
          
    usdlc.section_path = ->
      caret = usdlc.page_editor.getSelection().getRanges()[0].startContainer
      for parent in caret.getParents(true)
        break if parent.getAttribute?('id') is 'document'
        owner = parent
      start = $(owner.$)
      if not start.is('h1,h2,h3,h4,h5,h6')
        start = start.prevAll('h1,h2,h3,h4,h5,h6').first()
      level = +start.prop("tagName")[1] ? 1
      section_path = [title: section = start.text(), element:start, level:level]
      start.prevAll('h1,h2,h3,h4,h5,h6').each ->
        parent = $(this)
        if (parent_level = +parent.prop("tagName")[1]) < level
          level = parent_level
          return section_path.unshift
            title: parent.text()
            element: parent
            level: level
        else
          return false  # found root
      return section_path
      
    window.onscroll = ->
      scroll_timer = setTimeout(set_hash, 500) if not scroll_timer
