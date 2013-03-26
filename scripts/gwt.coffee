# Copyright (C) 2012,13 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license

# This script expects a base directory, query string, hash
# It will run Setup.coffee from the base directory, then process each statement.
# Everything is anynchronous and output goes to stdout / stderr.
path = require 'path'
gwt = require 'gwt'; os = require 'system'

default_options =
  project: '../uSDLC2'
  document: 'Design'
  sections: '.*'
  script_path: 'gen/usdlc2'
  maximum_step_time: 30

help = ->
  console.log "usage: ./go gwt project=<project-path> document=<document> sections=[section-path]..."

module.exports = (args...) ->
  program = "./go gwt"
  return os.help(program, default_options) if not args.length
  # This script expects a base directory followed by statement script names.
  console.log "./go gwt #{args.join(' ')}"
  options = os.command_line default_options

  # process.chdir options.project if options.project
  gwt = gwt.load options
  gwt.on_exit -> process.exit(gwt.error_code)
  # so we don't exit until all is done
  process.stdin.resume()
