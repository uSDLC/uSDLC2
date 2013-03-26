# Copyright (C) 2013 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license
EventEmitter = require('events').EventEmitter
path = require 'path'; timer = require 'timer'
line_reader = require 'line_reader'; steps = require 'steps'
script_extractor = require 'script_extractor'

class GWT extends EventEmitter
  constructor: (@options) ->
    gwt = @
    @options.document_path = path.join @options.project, "usdlc2/#{@options.document}.html"
    @options.script_path = path.join @options.project, @options.script_path
    scripts = []; @actions = []; @tests = 0; @patterns = []
    @statement_skip = @section_skip = 0; @failures = 0
    section_path = ''; @cleanups = []; @skipped = 0
    @after_sections = []; @paused_timeout = null

    @skip = (msg) -> @pass "# SKIP #{msg}", @skipped++
    # gwt.skip.statements(1) # skip one or more statements in the current script
    @skip.statements = (count = 1) => @statement_skip = count
    # gwt.skip.script() # skip the currently running script (eg. Given, When, Then)
    @skip.section = (msg) => @skip.sections 1, msg
    # gwt.skip.sections(1) # skip the current section
    @skip.sections = (count, msg) =>
      @statement_skip = Infinity
      @section_skip = count
    # gwt.skip.all() # terminate test run
    @skip.all = => @statement_skip = @section_skip = Infinity

    steps(
      # 1: extract scripts from documentation (if newer)
      ->  script_extractor(gwt.options).on 'end', @next
      # 2: read a list of available scripts
      ->
        reader = line_reader.for_file gwt.options.runner_file, (line) =>
          scripts.push line
        reader.on 'end', @next
      # 3: load tests - either gwt or explicitly in coffee-script
      ->
        gwt.timer = timer pre: '# ', post: ''
        re = new RegExp(gwt.options.sections ? '')
        scripts = (script for script in scripts when re.test script)
        read_script = =>
          if not scripts.length
            gwt.section()
            return @next()
          script = scripts.shift()
          if (script_section = path.dirname script) isnt section_path
            gwt.section section_path = script_section
          if path.extname(script) is '.gwt'
            reader = line_reader.for_file script, (statement) =>
              if statement?.length
                gwt.add (gwt) -> gwt.test_statement statement
            reader.on 'end', read_script
          else
            script = path.resolve fs.base(), script
            actor = require(script)
            if typeof actor is 'function'
              switch actor.length
                when 0 then gwt.add actor # direct actor
                when 1 then actor gwt, read_script # asynchronous
                else actor gwt; read_script() # synchronouus
            else
              read_script()
        read_script() # kick off sequential reading of scripts
      # 4: run the tests
      -> gwt.go()
      )
  # done with load as it has already created an instance
  load: -> @
  # add an actor to be run to create a test
  add: (test_list...) ->
    for test in test_list
      @actions.push test
      @tests++
    return @

  # call to separate sections
  section: (name) ->
    @actions.push (gwt) =>
      @section_skip -= 1 if @section_skip
      @statement_skip = 0 if not @section_skip
      name = if name then name.split('/').slice(-1)[0].replace('_', ' ') else ''
      console.log "#1 Section: #{name}" if name
      func = =>
        return @next() unless @after_sections.length
        @after_sections.shift()(func)
      func()
      @timer.elapsed()

  test_statement: (statement) ->
    # Look for a matching statement, then process the action
    for pattern, index in @patterns by 2
      if matched = pattern.exec(statement)
        # matched = (match.toString() for match in matched)
        matched = matched[1..] if matched.length > 1
        # jump statements if asked to do so
        return @skip('', @statement_skip--) if @statement_skip
        @title statement
        return @patterns[index + 1].apply(@, matched)
    @fail """
           Unknown statement, add:
             gwt.rules(
               /#{statement.replace(/\//g, '.')}/, () =>
                 @todo 'implement'
             )"""
  # display a test line title
  title: (text) -> console.log "#2    #{text}"
  # called by instrumentation scripts to set up rules for gwt
  rules: (patterns...) -> @patterns = @patterns.concat(patterns); return @

  # called if test passes
  pass: (msg = '') ->
    console.log "ok #{++@count} - #{msg}"
    @next()

  # called if test fails
  fail: (msg = '') ->
    @failures++
    console.log "not ok #{++@count} - #{msg}"
    @skip.section('fail')
    @next()

  expect: (value, to_be) ->
    if value is to_be
      @pass "'#{value}' correct"
    else
      @fail "'#{value}' isn't '#{to_be}'"

  # go to next script without marking pass or failure
  go: -> @next()
  next: ->
    if @tests
      console.log """
                  TAP version 13
                  1..#{@tests}"""
      @count = 0
      @next = @next_next
      @next()
    else
      console.log "# No tests"
      @exit()
  next_next: ->
    clearTimeout @paused_timeout
    @paused_timeout = setTimeout ( =>
      @fail """
             gwt did not resume in #{@options.maximum_step_time} seconds <e>
               increase gwt.maximum_step_time in seconds if needed <t>"""),
                                 @options.maximum_step_time * 1000
    return @actions.shift()(gwt) if @actions.length
    # all done - clean up
    clearTimeout @paused_timeout
    percent = Math.floor((@tests - @failures - @skipped) * 100 / @tests)
    console.log "Failed #{@failures}/#{@tests}, #{@skipped} skipped, #{percent}% okay"
    @timer.total()
    @exit()

  # call if test is not yet created
  todo: (msg) -> @fail "# TODO #{msg ? 'under construction'}"

  # call if test is not valid in the current setting
  skip: (msg = '') -> @pass "# SKIP #{msg}"

  # extend gwt with methods of interest to the current test suite
  extend: (modules...) ->
    for extension in modules
      extension = extension.replace /\s/g, '_'
      if extension[0] is '/'
        extension = path.resolve fs.base @options.script_path, extension
      for name, func of require extension
        GWT.prototype[name] = func
    return @

  on_exit: (func) -> @cleanups.unshift func
  exit: ->
    func = =>
      return if not @cleanups.length
      cleanup = @cleanups.shift()
      cleanup(func)
      func() if not cleanup.length #synchronous
    func()

module.exports =
  load: (@options) -> module.exports = global.gwt = new GWT @options
