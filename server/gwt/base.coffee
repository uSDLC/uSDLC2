# Copyright (C) 2013 paul@marrington.net, see GPL for license
EventEmitter = require('events').EventEmitter
path = require 'path'; timer = require 'common/timer'
dirs = require 'dirs'

module.exports =
  # called if test passes
  pass: (msg = '') ->
    # pass can't really pass if there is more to do
    @pass_messages.push msg.toString()
    if not @next_test()
      msg = @pass_messages.join(' - ')
      msg = " - #{msg}" if msg.length
      if expect_failure
        expect_failure = false
        @fail(message) # because we did not fail???
      else
        console.log "\nok #{++@count}#{msg}"
      @next()
  # called if test fails
  fail: (msg = '') ->
    negate = 'not '
    if expect_failure
      expect_failure = false
      negate = ''
    else
      @failures++
    msg = msg.toString()
    msg = " - #{msg}" if msg.length
    console.log "\n#{negate}ok #{++@count}#{msg}"
    console.log msg.stack if msg?.stack
    @skip.section('fail')
    @tests = []
    @next_test()
    @next()
  # where we are testing for failures
  expect_failure: false
  # test and show message on failure
  test: (test, msg = '') ->
    if test then @pass msg else @fail msg
  # pass err and fail if it exists
  check_for_error: (err, msg = '') ->
    if err then @fail err else @pass msg
    return err
  # test and provide a message if not as expected
  check: (value, to_be) ->
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
