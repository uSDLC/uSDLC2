# Copyright (C) 2013 paul@marrington.net, see GPL for license
processes = require 'processes'; dirs = require 'dirs'

module.exports = (ws) ->
  launcher = processes()
  launcher.options.stdio = 'pipe'
  project = 'uSDLC2'
  project = ws.upgradeReq.url.split('=')[1] ? 'uSDLC2'
  launcher.options.cwd = dirs.projects[project]
  shell = launcher.cmd (error) ->
    ws.emit 'error', error if error
    ws.close 0, "Shell process terminated"
  ws.from_browser.pipe(shell.proc.stdin)
  shell.proc.stdout.pipe(ws.to_browser)
  shell.proc.stderr.pipe(ws.to_browser)