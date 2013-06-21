# Copyright (C) 2012,13 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license

# This script expects a base directory, query string, hash
# It will run Setup.coffee from the base directory, then process each statement.
# Everything is anynchronous and output goes to stdout / stderr.
path = require 'path'; gwt = require 'gwt'; os = require 'system'
Stream = require('stream').Stream

default_options =
  project: '../uSDLC2'
  document: 'Design'
  sections: '.*'
  script_path: 'gen/usdlc2'
  maximum_step_time: 30

stdout = null
forked_writer = (string, encoding, fd)  -> process.send string
shelled_writer = (string, encoding, fd) -> stdout(string, encoding, fd)
writer = shelled_writer

help = -> console.log(
  "usage: ./go gwt project=<project-path>
  document=<document> sections=[section-path]...")

module.exports = (args...) ->
  return os.help("./go gwt", default_options) if not args.length
  # This script expects a base directory followed by statement script names.
  options = os.command_line()
  options[key] ?= value for key, value of default_options

  process.chdir options.project if options.project
  # if we are formed from uSDLC2, send stdout/stderr back via messages
  stdout = process.stdout.write; stderr = process.stderr.write
  process.stdout.write = if options.forked then forked_writer else shelled_writer
  console.log "#: ./go gwt '#{args[0..-2].join("' '")}'"
  # Load rules and start processing
  gwt = gwt.load(options)
  gwt.on_exit ->
    process.stdout.write = stdout; process.stderr.write = stderr
    process.exit(gwt.error_code)
  # so we don't exit until all is done
  process.stdin.resume()
