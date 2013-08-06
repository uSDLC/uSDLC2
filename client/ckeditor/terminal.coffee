# Copyright (C) 2013 paul@marrington.net, see GPL for license
module.exports = (exchange) ->
  exchange.respond.client ->
    web_service = (term, next) ->
      return next(term.ws) if term.ws
      ws = new WebSocket(
        "ws://#{location.host}/server/http/shell.coffee?"+
        "project=#{localStorage.project}")
      ws.onopen = -> next(term.ws = ws)
      ws.onmessage = (event) ->
        term.echo(event.data)
      ws.onclose = (event) ->
        roaster.message "<b>Terminal Closed</b>"
        term.ws = null

    evaluate = (command, term) ->
      web_service term, (ws) -> ws.send("#{command}\n")
      return ''
    
    term = null
    
    term_options =
      tabcompletion: true
      greetings: ''
      onInit: (terminal) ->
        term = terminal
        usdlc.page_editor.on 'focus', -> term.disable()
      completion: (term, cmd, list) ->
        data = term.history().data(); l = cmd.length
        list (item for item in data when item[0...l] is cmd)
      historyFilter: (cmd) ->
        for item in term.history().data()
          return false if cmd is item
        return true
    
    init = (dlg) ->
      dlg.append(dlg.term = $('<div/>'))
      dlg.term.terminal(evaluate, term_options)
      dlg.term.height(dlg.height() - 20)
      dlg.term.css('overflow', 'hidden')
        
    dialog_options =
      width: 600
      height: 400
      position:
        my: "right-100 bottom-50"
        at: "right bottom"
        of: window
      init: init
      
    dlg = null
    on_resize = ->
      height = dlg.height() - 20
      dlg.term.height(height)
      
    usdlc.terminal = ->
      steps(
        -> @on 'error', -> @abort()
        -> @requires '/client/dialog.coffee'
        ->
          dlg = @dialog
            name: 'Terminal'
            title: 'Console'
            fill: ->
            after: @next
            resizeStop: (dlg) -> on_resize(dlg)
            dialog_options
      )
      
    CKEDITOR.plugins.add 'terminal',
      icons: 'terminal',
      init: (editor) ->
        editor.addCommand 'terminal', exec: usdlc.terminal
        editor.ui.addButton 'terminal',
          label:    'Console (alt-T)'
          command:  'terminal'
          toolbar:  'uSDLC,9'
        editor.setKeystroke(CKEDITOR.ALT + 84, 'terminal')
