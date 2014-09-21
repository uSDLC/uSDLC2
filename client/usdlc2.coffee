# Copyright (C) 2013 paul@marrington.net, see GPL for license

picture = mvc:'html_editor', options: fullPage: true

require 'mvc', (imports) ->
  imports.mvc picture, document.body, (err, ed) ->
    return gwt.fail(err) if err
    process.nextTick ->
      ed.ckeditor.setData "The rain in spain"
