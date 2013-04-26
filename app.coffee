# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license

roaster.load "jquery,ckeditor", ->
  editor = roaster.ckeditor.open 'document',
    filebrowserBrowseUrl: '/server/file_browser.coffee'
    filebrowserImageBrowseLinkUrl: '/server/image_browser.coffee'
    filebrowserImageBrowseUrl: '/server/image_browser.coffee'
    filebrowserUploadUrl: '/server/image_upload.coffee'
