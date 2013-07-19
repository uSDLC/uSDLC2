# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
roaster.environment.mode_map =
  coffee:       'coffeescript'
  'gwt.coffee': 'coffeescript'
  js:           'javascript'
  json:         'application/json'
instance_index = 0
cm = null; context_menu = null; selected = ->
spaces = '                '

module.exports.initialise = (next) ->
  CodeMirror.modeURL = '/ext/codemirror/codemirror/mode/%N/%N.js'

  _.extend CodeMirror.commands,
    fold_at_cursor: (cm) -> cm.foldCode(cm.getCursor())
    play_current: (cm) -> roaster.replay()
    toggle_auto_complete: (cm) -> alert "Under Construction"
    merge_local: (cm) -> alert "Under Construction"
    merge_remote:  (cm) -> alert "Under Construction"
    view_source: (cm) -> alert "Under Construction"
    toggle_option: (cm, name) ->
      CodeMirror.commands.set_option(cm, name, not cm.getOption(name))
    set_option: (cm, name, value) ->
      cm.setOption(name, value)
      opt = _.clone cm.options
      delete opt.value
      localStorage['CodeMirrorOptions'] = JSON.stringify opt
    set_mode: (cm, mode) ->
      cm.setOption('keyMap', mode)
      prepare_menu(cm)
    auto_complete: (cm) ->
      CodeMirror.showHint(cm, CodeMirror.hint.anyword, completeSingle: false)
    defaultTab: (cm) ->
      if cm.somethingSelected()
        cm.indentSelection("add");
      else
        tab = cm.getOption("indentUnit") + 1
        cm.replaceSelection(spaces[0..tab], "end", "+input")

  if options = localStorage.CodeMirrorOptions
    options = JSON.parse(options)
  else
    options =
      lineNumbers:    true
      foldGutter:     true
      gutters:        ["CodeMirror-lint-markers", "CodeMirror-foldgutter"]
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

  prepare_menu = (cm) ->
    key_map = {}
    one_map = (map) ->
      for key, cmd of map
        key_map[cmd] = '' if not key_map[cmd]
        key_map[cmd] += ' ' + key
      if typeof map.fallthrough is 'string'
        one_map(CodeMirror.keyMap[map.fallthrough])
      else if map.fallthrough
        one_map(CodeMirror.keyMap[map]) for map in map.fallthrough
    one_map cm.options.extraKeys
    one_map CodeMirror.keyMap[cm.options.keyMap]

    menu = context_menu.clone(true).appendTo('body')
    menu.find('a').each (index, element) ->
      a = $(element)
      return if not (cmd = a.attr('action')).length
      a.attr('href', 'javascript:;')
      a.attr('title', key) if key = key_map[cmd]
    $(cm.getWrapperElement()).contextmenu 'replaceMenu', menu

  usdlc.source_editor =
    edit: (element, source) ->
      mode = source.attr('type')
      mode = roaster.environment.mode_map[mode] ? mode
      editor = CodeMirror element.get(0), _.extend {}, options,
        mode:           mode
        value:          source.text()
        extraKeys:      extra_keys
      CodeMirror.autoLoadMode(editor, mode)
      editor.id = "codemirror_#{++instance_index}"
      update = -> source.text(editor.getValue())
      editor.on 'change', ->
        usdlc.save_timer editor.id, update
        return if cm.somethingSelected()
        cursor = cm.doc.getCursor()
        line = cm.doc.getLine(cursor.line)
        if cursor.ch and line[cursor.ch - 1].match(/^[0-9a-zA-Z_]$/)
          CodeMirror.commands.auto_complete(editor)
      editor.on 'focus', -> cm = editor
      editor.on 'blur', -> update(); usdlc.save_page()
      (element = $(editor.getWrapperElement())).contextmenu
        select: (event, ui) ->
          a = ui.item.find('a')
          cmd = a.attr('action')
          return if not cmd?.length
          args = a.attr('args')?.split(',') ? []
          selected = -> CodeMirror.commands[cmd]?(editor, args...)
          return true
        close: (event) ->
          editor.focus()
          selected()
          selected = ->
      prepare_menu(editor)
      $(":input, a").attr("tabindex", "-1") # so tab stays in editor
      return editor
  steps(
    ->  @data '/client/codemirror/menu.html'
    ->  context_menu = $(@menu).appendTo('body')
  )
  next()
