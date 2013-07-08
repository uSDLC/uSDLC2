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
      # history.pushState from, '', "#{pathname}?edit##{hash ? ''}"

    outline = ->
      listeners = []
      $('h1,h2,h3,h4,h5,h6', usdlc.document).each ->
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
          toolbar: 'uSDLC,3'
          
    headers = -> usdlc.document.find('h1,h2,h3,h4,h5,h6')

    usdlc.goto_section = (name) ->
      sectionElements = {}
      headers().each -> sectionElements[@innerHTML] = @
      return if not name or not sectionElements[name]
      goto_section sectionElements[name]

    scroll_timer = null
    
    set_hash = ->
      scroll_timer = null
      top = usdlc.page_editor.document.$.body.scrollTop; done = false
      headers().each ->
        return if done
        section_top = $(@).offset().top
        if section_top > top
          window.location.hash = hash = @innerHTML
          localStorage.url = localStorage.url.split('#')[0] + "##{hash}"
          done = true
          
    usdlc.section_path = ->
      caret = usdlc.page_editor.getSelection().getRanges()[0].startContainer
      # last parent before <body> is top of line
      start = caret.getParents(true)[-3..-3]
      return [] if not start.length #pointing to body (no elements)
      start = $(start[0].$)
      if not start.is('h1,h2,h3,h4,h5,h6')
        start = start.prevAll('h1,h2,h3,h4,h5,h6').first()
      return [] if not start.length # In text above first header
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
      
    setter = -> usdlc.page_editor.document?.$.onscroll = ->
      scroll_timer = setTimeout(set_hash, 500) if not scroll_timer
    usdlc.page_editor.on 'dataReady', setter
    # switching to html and back loses setter. Tried on mode, but
    # doc element no longer has a defaultView (window) in iframe
    # usdlc.page_editor.on 'mode', setter
