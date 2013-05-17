# Copyright (C) 2013 paul@marrington.net, see GPL for license
EventEmitter = require('events').EventEmitter
path = require 'path'; timer = require 'common/timer'; dirs = require 'dirs'
line_reader = require 'line_reader'; steps = require 'steps'
script_extractor = require 'script_extractor'

module.exports =
  # called if test passes
  pass: (msg = '') -> console.log "ok #{++@count} - #{msg}"; @next()
  # called if test fails
  fail: (msg) ->
    @failures++
    console.log "not ok #{++@count} - #{msg}"
    console.log msg.trace if msg.trace
    @skip.section('fail')
    @next() 
  # test and show message on failure
  test: (test, msg = '') -> if test then @pass msg else @fail msg
  # pass err and fail if it exists
  check_for_error: (err, msg = '') -> if err then @fail err else @pass msg
  # test and provide a message if not as expected
  expect: (value, to_be) ->
    if value is to_be
      @pass "'#{value}' correct"
    else
      @fail "'#{value}' isn't '#{to_be}'"
  # call if test is not yet created
  todo: (msg) -> @fail "# TODO #{msg ? 'under construction'}"
  # call if test is not valid in the current setting
  skip: (msg = '') -> @pass "# SKIP #{msg}"
  # require a file from the project under test
  require: (name) -> return require path.join @options.project, name
  # what to do when gwt has finished (close servers, etc)
  on_exit: (func) -> @cleanups.unshift func
