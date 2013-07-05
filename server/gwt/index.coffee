# Copyright (C) 2013 paul@marrington.net, see GPL for license
EventEmitter = require('events').EventEmitter
path = require 'path'; timer = require 'common/timer'; dirs = require 'dirs'
line_reader = require 'line_reader'; steps = require 'steps'
script_extractor = require 'script_extractor'; Rules = require 'common/rules'
require 'common/strings'

require.extensions['.gwt.coffee'] = require.extensions['.coffee']

class GWT extends EventEmitter
  constructor: (@options) ->
    gwt = @
    # initialise important variables
    @options.document_path = path.join(
      @options.project, "usdlc2/#{@options.document}.html")
    @options.script_path = path.join @options.project, @options.script_path
    scripts = []; @actions = []; @tests = 0; @ruler = new Rules(@)
    @statement_skip = @section_skip = 0; @failures = 0
    @cleanups = []; @skipped = 0
    @after_sections = []; @paused_timeout = null
    @extensions = {}
    # first we take control of stdout and stderr
    @stdout = process.stdout.write; @stderr = process.stderr.write
    @cleanups.push ->
      process.stdout.write = @stdout; process.stderr.write = @stderr
    @output_array = []
    process.stdout.write = => @gwt_out arguments...
    process.stderr.write = => @gwt_err arguments...
    # all about skipping
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
      ->  script_extractor gwt.options, @next
      # 2: read a list of available scripts
      ->
        reader = line_reader.for_file gwt.options.runner_file, (line) =>
          scripts.push line
        reader.on 'end', @next
      # 3: load tests - either gwt or explicitly in coffee-script
      ->
        @asynchronous()
        gwt.timer = timer pre: '# ', post: ''
        re = new RegExp(gwt.options.sections ? '')
        scripts = (script for script in scripts when re.test script)
        processed_scripts = {}            
        do read_script = =>
          if not scripts.length then gwt.section(); return @next()
          gwt.section script = scripts.shift()
          ext_name = path.extname(script)
          switch ext_name
            when '.gwt'
              reader = line_reader.for_file script, (statement) =>
                if statement?.length and statement[0] isnt '#'
                  gwt.add (gwt) -> gwt.test_statement statement
              reader.on 'end', read_script
            when '.coffee'
              parents = []; base = script.split('.')[0]
              if script.ends_with('.gwt.coffee')
                ext_name = '.gwt.coffee'
                while base.length and base isnt '.'
                  parents.push(base)
                  base = path.dirname(base)
                parents.pop() if parents[scripts.length - 1] is 'gen'
                parents.pop() if parents[scripts.length - 1] is 'usdlc2'
              else
                parents = [base]
                
              do next = ->
                return read_script() if not parents.length
                script = parents.pop() + ext_name
                return next() if processed_scripts[script]
                processed_scripts[script] = script
                try
                  actor = require(path.resolve dirs.base(), script)
                  if typeof actor is 'function'
                    switch actor.length
                      when 0 then gwt.add(actor) # direct actor
                      when 1 then actor(gwt, next); return # asynchronous
                      else actor(gwt) # synchronouus
                catch err
                next()
      # 4: run the tests
      -> gwt.go()
      )
  # done with load as it has already created an instance
  load: -> @
  gwt_out: (string, encoding, fd) ->
    @output_array.push string
    @stdout string, encoding, fd
  gwt_err: (string, encoding, fd) ->
    @output_array.push '#!! ', string
    @stdout string, encoding, fd
  output: -> (output_array = [@output_array.join('')])[0]
  # add an actor to be run to create a test
  add: (test_list...) ->
    for test in test_list
      @actions.push test
      @tests++
    return @

  # call to separate sections
  section: (name) ->
    @actions.push (gwt) =>
      return @next() if @actions.length is 1  # no actions for this section
      @section_skip -= 1 if @section_skip
      @statement_skip = 0 if not @section_skip
      name = /([^\/]+)\.[\w\.]+$/.exec(name)?[1].replace(/_/g, ' ')
      console.log "#1 Section: #{name}" if name
      do func = =>
        return @next() unless @after_sections.length
        section = @after_sections.shift()
        try section(func) catch error
          console.log section.toString()
          throw error
      @timer.elapsed()

  test_statement: (statement) ->
    return @skip('', @statement_skip--) if @statement_skip
    @title statement
    if not @ruler.run(statement)
      @fail """
             Unknown statement, add:
               gwt.rules(
                 /#{statement.replace(/\//g, '.')}/, () =>
                   @todo 'implement'
               )"""
  # called by instrumentation scripts to set up rules for gwt
  rules: (patterns...) -> @ruler.add(patterns...); return @
  # display a test line title
  title: (text) -> console.log "#2    #{text}"

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
             gwt did not resume in #{@options.maximum_step_time} seconds
               increase gwt.maximum_step_time in seconds if needed"""),
                                 @options.maximum_step_time * 1000
    try
      action = @actions.shift()
      return action(gwt) if @actions.length
    catch err
      console.log action.toString()
      return @fail err
    # all done - clean up
    clearTimeout @paused_timeout
    passes = @tests - @failures - @skipped
    percent = Math.floor(passes * 100 / @tests)
    console.log "Failed #{@failures}/#{@tests}, #{@skipped} skipped, #{percent}% okay"
    @timer.total()
    @exit()
  # extend gwt with methods of interest to the current test suite
  extend: (modules...) ->
    for extension in modules
      extension = extension.replace /\s/g, '_'
      if extension[0] is '/'
        extension = path.resolve path.join @options.script_path, extension
      if not @extensions[extension]
        @extensions[extension] = require extension
        GWT.prototype[name] = func for name, func of @extensions[extension]
    return @
  # all done ... clean up
  exit: ->
    do next_cleanup = =>
      return if not @cleanups.length
      cleanup = @cleanups.shift()
      steps(cleanup, next_cleanup)

  server: -> @server = require 'gwt/server'
  process: (type) -> return require('gwt/processes')(type)

module.exports =
  load: (@options) ->
    module.exports = global.gwt = gwt = new GWT @options
    gwt.extend 'gwt/base'
    require 'gwt/rules'
    return gwt
