# Copyright (C) 2013 paul@marrington.net, see GPL for license
processes = require 'processes'; dirs = require 'dirs'

module.exports = (ws) ->
  launcher = processes()
  launcher.options.stdio = 'pipe'
  project = ws.url.query.project ? 'uSDLC2'
  launcher.options.cwd = dirs.projects[project]
  shell = launcher.cmd (error) ->
    ws.emit 'error', error if error
    ws.close 0, "Shell process terminated"
  streams = ws.streams()
  streams.from_browser.pipe(shell.proc.stdin)
  shell.proc.stdout.pipe(streams.to_browser)
  shell.proc.stderr.pipe(streams.to_browser)