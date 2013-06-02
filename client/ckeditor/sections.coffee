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
      $('h1,h2,h3,h4,h5,h6').each ->
        heading = CKEDITOR.dom.element.get @
        heading.on 'click', ->
          usdlc.document.children().show()
          usdlc.sources().hide()
          goto_section heading.$
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
    window.onscroll = ->
      scroll_timer = setTimeout(set_hash, 500) if not scroll_timer
