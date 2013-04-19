# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
sceditor_base = "/ext/sceditor/SCEditor-1.4.2/"

roaster.load "sceditor", ->
  $('#sceditor').sceditor(
    toolbar:  "bold,italic,underline,strike,subscript,superscript|
      left,center,right,justify|
      font,size,color,removeformat|pastetext|bulletlist,orderedlist|
      table|code,quote|horizontalrule,image,email,link,unlink|date,time|
      print,source"
    plugins: "xhtml"
    style: "#{sceditor_base}minified/themes/default.min.css"
    emoticons: []
    emoticonsEnabled: false
    emoticonsRoot: sceditor_base
    width: '100%'
    height: '100%'
    autofocus: true
  )
