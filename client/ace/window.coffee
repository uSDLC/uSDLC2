sources = document.getElementsByTagName('textarea')
console.log document
for textarea in sources
  type = textarea.getAttribute('type')
  if type?.length
    div = document.createElement('div')
    div.setAttribute('style', "
      position: relative;
      top: 0;
      right: 0;
      bottom: 0;
      left: 0;
      height: 200px;
      width: 99%;
      border: 1px solid #eee;
      z-index: 10000;
    ")
    textarea.setAttribute 'style', 'display:none;'
    textarea.parentNode.appendChild div
    editor = ace.edit(div)
    editor.setTheme("ace/theme/twilight");
    editor.getSession().setMode("ace/mode/#{type}")
    # editor.on 'change', pre pre.text(editor.getValue())
