# Copyright (C) 2013 paul@marrington.net, see /GPL for license
roaster.environment.mode_map =
  c: 'clike', cpp: 'clike', h: 'clike', cs: 'clike'
  java: 'clike', sh: 'shell'
  clj: 'clojure', coffee: 'coffeescript'
  cl: 'commonlisp', lsp: 'commonlisp', el: 'commonlisp'
  lhs: 'haskell', gs: 'haskell', hs: 'haskell'
  html: 'htmlmixed', htm: 'htmlmixed'
  js: 'javascript', json: 'javascript', ls: 'livescript'
  pas: 'pascal', py: 'python', 'sh': 'shell', bas: 'vbscript'
  'gwt.coffee': 'coffeescript'
  
alnum = /^[0-9a-zA-Z_]$/

instance_index = 0
cm = null; context_menu = null; selected = ->
spaces = '                '

module.exports.initialise = (next) ->
  CodeMirror.modeURL =
    '/ext/codemirror/CodeMirror-master/mode/%N/%N.js'

  _.extend CodeMirror.commands,
    fold_at_cursor: (cm) -> cm.foldCode(cm.getCursor())
    play_current: (cm) -> roaster.replay()
    file_manager: (cm) -> queue ->
      @requires '/client/tree_filer.coffee', -> @tree_filer()
    toggle_auto_complete: (cm) -> alert "Under Construction"
    view_source: (cm) ->
      if cm.somethingSelected()
        coffeescript = cm.doc.getSelection()
      else
        coffeescript = cm.doc.getValue()
      try
        javascript =
          CoffeeScript.compile(coffeescript, bare:true)
      catch e
        javascript = "#{e}\n#{JSON.stringify(e.location)}"
      queue -> @requires '/client/codemirror/editor.coffee', ->
        @editor
          name:     'Javascript'
          title:    'Javascript'
          position:
            my: "left top+60", at: "left+10 top", of: window
          source:
            attr: (-> 'javascript'), text: (-> javascript)
    toggle_option: (cm, name) ->
      value = not cm.getOption(name)
      CodeMirror.commands.set_option(cm, name, value)
    set_option: (cm, name, value) ->
      cm.setOption(name, value)
      opt = _.clone cm.options
      delete opt.value
      localStorage['CodeMirrorOptions'] = JSON.stringify(opt)
    set_mode: (cm, mode) ->
      CodeMirror.commands.set_option(cm, 'keyMap', mode)
      prepare_menu(cm)
    auto_complete: (cm) ->
      anyword = CodeMirror.hint.anyword
      notOnly = -> # don't show if an exact match
        result = anyword.apply null, arguments
        list = result.list
        result.list = [] if list.length is 1 and
          list[0].length is (result.to.ch - result.from.ch)
        return result
      CodeMirror.showHint(cm, notOnly, completeSingle: false)
    defaultTab: (cm) ->
      if cm.somethingSelected()
        cm.indentSelection("add")
      else
        tab = cm.getOption("indentUnit") + 1
        cm.replaceSelection(spaces[0..tab], "end", "+input")

  if options = localStorage.CodeMirrorOptions
    options = JSON.parse(options)
  else
    options =
      lineNumbers:    true
      foldGutter:     false
      gutters:        ["CodeMirror-lint-markers",
                       "CodeMirror-foldgutter"]
      lint:           true
      matchBrackets:  true
      autoCloseBrackets:true
      matchTags:      true
      showTrailingSpace:true

  extra_keys =
    'Cmd-Left':   'goLineStartSmart'
    'Ctrl-Q':     'fold_at_cursor'
    'Alt-P':      'play_current'
    'Ctrl-Space': 'auto_complete'
    'Cmd-/':      'toggleComment'
    'Alt-M':      'merge_local'
    'Shift-Cmd-M':'merge_remote'
    'Alt-<':      'goColumnLeft'
    'Alt->':      'goColumnRight'
    'Ctrl-Shift-F':'clearSearch'
    'Alt-{':      'toMatchingTag'
    'Alt-S':      'view_source'
    'Alt-V':      'file_manager'

  prepare_menu = (cm) ->
    key_map = {}
    one_map = (map) ->
      for key, cmd of map
        key_map[cmd] = '' if not key_map[cmd]
        key_map[cmd] += ' ' + key
      if typeof map.fallthrough is 'string'
        one_map(CodeMirror.keyMap[map.fallthrough])
      else if map.fallthrough
        for map in map.fallthrough
          one_map(CodeMirror.keyMap[map])
    one_map cm.options.extraKeys
    core = CodeMirror.keyMap[cm.options.keyMap]
    if not core.fallthrough
      core.fallthrough =
        CodeMirror.keyMap['default'].fallthrough
    one_map core

    menu = context_menu.clone(true).appendTo('body')
    menu.find('a').each (index, element) ->
      a = $(element)
      return if not (cmd = a.attr('action')).length
      a.attr('href', 'javascript:;')
      a.attr('title', key) if key = key_map[cmd]
    $(cm.getWrapperElement()).contextmenu 'replaceMenu', menu

  usdlc.source_editor =
    edit: (element, source) ->
      mode = source.attr('type') ? 'text'
      mode = roaster.environment.mode_map[mode] ? mode
      editor = CodeMirror element.get(0),
        _.extend {}, options,
          # mode:     mode
          autofocus: true
          value:     source.text()
          extraKeys: extra_keys
          lint:      mode in ['javascript', 'coffeescript']
      editor.setOption 'mode', mode
      CodeMirror.autoLoadMode(editor, mode)
      editor.id = "codemirror_#{++instance_index}"
      update = -> source.text(editor.getValue())
      allow_autocomplete = false
      editor.on 'change', ->
        usdlc.save_timer editor.id, update
        return if cm.somethingSelected()
        cursor = cm.doc.getCursor()
        line = cm.doc.getLine(cursor.line)
        if cursor.ch and allow_autocomplete and
        line[cursor.ch - 1].match(alnum)
          CodeMirror.commands.auto_complete(editor)
      editor.on 'keydown', (cm, event) ->
        allow_autocomplete = false
      editor.on 'keypress', (cm, event) ->
        ch = String.fromCharCode(event.which ? event.keyCode)
        allow_autocomplete = true if ch.match(alnum)
      editor.on 'focus', -> cm = editor
      editor.on 'blur', -> update(); usdlc.save_page()
      (element = $(editor.getWrapperElement())).contextmenu
        select: (event, ui) ->
          a = ui.item.find('a')
          cmd = a.attr('action')
          return if not cmd?.length
          args = a.attr('args')?.split(',') ? []
          selected = ->
            CodeMirror.commands[cmd]?(editor, args...)
          return true
        close: (event) ->
          editor.focus()
          selected()
          selected = ->
      prepare_menu(editor)
      # so tab stays in editor
      $(":input, a").attr("tabindex", "-1")
      if usdlc.grep # highlight search term from grep
        re = new RegExp(usdlc.grep)
        cursor = editor.getSearchCursor(re, null, false)
        if cursor.findNext()
          scroller = ->
            editor.scrollIntoView(cursor.from(), 100)
          setTimeout scroller, 1000
          editor.setSelection(cursor.from(), cursor.to())
      setTimeout (-> editor.focus()), 500
      return editor
  queue -> @data '/client/codemirror/menu.html', ->
    context_menu = $(@menu).appendTo('body')
  next()
