# Copyright (C) 2013 paul@marrington.net, see GPL for license
EventEmitter = require('events').EventEmitter
path = require 'path'; timer = require 'common/timer'
dirs = require 'dirs'; line_reader = require 'line_reader'

module.exports =
  # called if test passes
  pass: (msg = '') ->
    # pass can't really pass if there is more to do
    @pass_messages.push msg.toString()
    if @step.empty()
      msg = @pass_messages.join(' - ')
      msg = " - #{msg}" if msg.length
      console.log "ok #{++@count}#{msg}"
      @next()
    else
      @step.next()
  # called if test fails
  fail: (msg) ->
    @failures++
    msg = msg.toString()
    msg = " - #{msg}" if msg.length
    console.log "not ok #{++@count}#{msg}"
    console.log msg.stack if msg?.stack
    @skip.section('fail')
    @step.abort()
    @next()
  # test and show message on failure
  test: (test, msg = '') ->
    if test then @pass msg else @fail msg
  # pass err and fail if it exists
  check_for_error: (err, msg = '') ->
    if err then @fail err else @pass msg
    return err
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
  require: (name) ->
    return require path.join @options.project, name
  # what to do when gwt has finished (close servers, etc)
  on_exit: (func) -> @cleanups.unshift func
  # check all output for included text
  includes_text: (included) ->
    return @output().indexOf(included) != -1
  matches_text: (re) ->
    return (new RegExp(re)).test(@output())