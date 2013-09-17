# Copyright (C) 2013 paul@marrington.net, see GPL for license
module.exports = (exchange) ->
  exchange.respond.client ->
    headings = 'h1,h2,h3,h4,h5,h6'

    goto_section = (heading) ->
      usdlc.document.removeClass('outline')
      hash = window.location.hash
      from = "#{window.location.pathname}?edit##{hash}"
      heading.scrollIntoView()
      document.body.scrollTop -= 60
      [pathname,hash] = usdlc.url.split('#')
      hash = heading.innerText
      usdlc.url = "#{pathname}##{hash}"
      # history.replaceState null, null, "#{pathname}?edit##{hash ? ''}"

    outline = ->
      listeners = []
      $(headings, usdlc.document).each ->
        heading = CKEDITOR.dom.element.get @
        listeners.push heading.on 'click', ->
          usdlc.document.children().show()
          usdlc.sources().hide()
          goto_section heading.$
          listener.removeListener() for listener in listeners
      usdlc.document.children().not(headings).hide()
      usdlc.document.addClass('outline')

    order = roaster.ckeditor.tools.sections
    CKEDITOR.plugins.add "sections",
      icons: 'sections',
      init: (editor) ->
        editor.addCommand 'sections',
          exec: (editor) -> outline()
        editor.ui.addButton 'sections',
          label: 'Document Sections',
          command: 'sections',
          toolbar: "uSDLC,#{order[0]}"

    headers = -> usdlc.document.find(headings)

    usdlc.goto_section = (name) ->
      sectionElements = {}
      headers().each -> sectionElements[@innerHTML] = @
      return if not name or not sectionElements[name]
      goto_section sectionElements[name]

    scroll_timer = null

    set_hash = ->
      scroll_timer = null; done = false
      top = usdlc.page_editor.document.$.body.scrollTop
      headers().each ->
        return if done
        section_top = $(@).offset().top
        if section_top > top
          window.location.hash = hash = @innerText
          no_hash = usdlc.url.split('#')[0]
          usdlc.url = "#{no_hash}##{hash}"
          done = true
    usdlc.get_caret = ->
      selection = usdlc.page_editor.getSelection()
      return selection.getRanges()[0].startContainer
    usdlc.section_for = (element) ->
      element = $(element)
      if not element.is(headings)
        element = element.prevAll(headings).first()
      return element
    current_section = ->
      caret = usdlc.get_caret()
      # last parent before <body> is top of line
      start = caret.getParents(true)
      if start.length < 3
        start = caret.$
      else
        start = start[-3..-3][0].$
      return usdlc.section_for(start)
    # find the last element in a section
    end_section = (start) ->
      return start.nextUntil(headings).last()
    # return a path to the current section
    usdlc.section_path = ->
      start = current_section()
      return [] if not start.length
      level = +start.prop("tagName")[1] ? 1
      section_path = [
        title:   section = start.text()
        element: start
        level:   level
      ]
      start.prevAll(headings).each ->
        parent = $(this)
        if (parent_level = +parent.prop("tagName")[1]) < level
          level = parent_level
          return section_path.unshift
            title:   parent.text()
            element: parent
            level:   level
      return section_path
    # look for an element in the current section
    usdlc.section_element = (header, selector, builder) ->
      header ?= current_section()
      possibles = header.nextUntil(headings)
      el = possibles.find(selector)
      el = possibles.filter(selector) if not el.length
      if not el.length
        el = builder().insertAfter(end_section(header))
      return el

    setter = -> usdlc.page_editor.document?.$.onscroll = ->
      if not scroll_timer
        scroll_timer = setTimeout(set_hash, 500)
    usdlc.page_editor.on 'dataReady', setter
    # switching to html and back loses setter.
    # Tried on mode, but doc element no longer has
    # a defaultView (window) in iframe
    # usdlc.page_editor.on 'mode', setter
