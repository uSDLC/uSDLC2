# Copyright (C) 2013 paul@marrington.net, see GPL for license
EventEmitter = require('events').EventEmitter
path = require 'path'; timer = require 'common/timer'
dirs = require 'dirs'

module.exports =
  constraint: -> @passes_required++
  # called if test passes
  pass: (msg) ->
    msg = @stringify msg
    # pass can't really pass if there is more to do
    return if @passes_required-- > 0
    @passes_required = 0

    @pass_messages.push msg if msg
    msg = @pass_messages.join(' - ')
    @pass_messages = []
    msg = " - #{msg}" if msg.length
    if expect_failure
      expect_failure = false
      @fail(message) # because we did not fail???
    else if @count >= 0
      @print "\nok #{++@count}#{msg}"
    @next()
  # called if test fails
  fail: (msg) ->
    msg = @stringify msg
    negate = 'not '
    if expect_failure
      expect_failure = false
      negate = ''
    else if @count >= 0
      @failures++
      msg = (++@count)+' - '+msg
      @skip.section('fail')
    else
      @skip.all('fail on pre')
    msg += "\n"+msg.stack if msg.stack
    console.log "\n#{negate}ok #{msg}"
    console.log msg.stack if msg?.stack
    @tests = []
    @passes_required = 0
    @next()
  # make messages the most readable
  stringify: (msg = '') ->
    if msg instanceof Object
      return "->\n" + JSON.stringify msg, null, 2
    else
      return msg.toString()
  # where we are testing for failures
  expect_failure: false
  # test and show message on failure
  test: (test, msg) ->
    if test then @pass msg else @fail msg
    return test
  failed: (test, msg) ->
    return false if not test
    @fail msg
    return true
  # parse err and fail if it exists
  check_for_error: (err, msg) ->
    if err then @fail err else @pass msg
    return err
  # test and provide a message if not as expected
  check: (value, to_be, msg) ->
    msg = @stringify msg
    valstr = @stringify value
    if @cmp(value, to_be)
      @pass "'#{valstr}'\n#{msg}"; return true
    else
      @fail "#{valstr}\nisn't\n#{@stringify(to_be)}\n#{msg}"
      return false
  cmp: (x, y) -> # detailed object comparison
    return true if x is y
    return false if x not instanceof Object
    return false if y not instanceof Object
    return false if x.constructor isnt y.constructor
    for k,v of x
      #continue if not x.hasOwnProperty(p)
      #return false if not y.hasOwnProperty(p)
      continue if v is y[k]
      return false if typeof v isnt "object"
      return false if not @cmp(v, y[k])
    for k,v of y
      #if y.hasOwnProperty(p) and not x.hasOwnProperty(p)
      #  return false
      return false if x[k] isnt v
    return true
  # call if test is not yet created
  todo: (msg) ->
    console.log "\nnot ok #{++@count} - #{msg}"
    @failures++
    @next()
  # call if test is not valid in the current setting
  skip: (msg) -> @pass "# SKIP #{msg}"
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
