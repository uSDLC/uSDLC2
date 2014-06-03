# Copyright (C) 2013 paul@marrington.net, see GPL for license
EventEmitter = require('events').EventEmitter
path = require 'path'; timer = require 'common/timer'
line_reader = require 'line_reader'
Rules = require 'common/rules'
script_extractor = require 'script_extractor'
require 'common/strings'

require.extensions['.gwt.coffee'] =
  require.extensions['.coffee']
gwt = null
  
class GWT extends EventEmitter
  constructor: (@options) ->
    gwt = @
    # initialise important variables
    docpath = "usdlc2/#{@options.document}.html"
    @options.document_path = docpath
    @all_scripts = []
    scripts = []; @preactions = []
    @actions = [-> @count = 0; @next()]; @count = -1
    @test_count = 0; @ruler = new Rules(gwt)
    @statement_skip = @section_skip = 0; @failures = 0
    @cleanups = []; @skipped = 0
    @after_sections = []; @paused_timeout = null
    @extensions = {}
    # first we take control of stdout and stderr
    @stdout = process.stdout.write
    @stderr = process.stderr.write
    @cleanup (next) ->
      process.stdout.write = @stdout
      process.stderr.write = @stderr
      next()
    @output_array = []
    process.stdout.write = => @gwt_out arguments...
    process.stderr.write = => @gwt_err arguments...
    # all about skipping
    @skip = (msg) -> @pass "# SKIP #{msg}", @skipped++
    # gwt.skip.statements(1) # skip one or more statements
    # in the current script
    @skip.statements = (count = 1) => @statement_skip = count
    # gwt.skip.script() # skip the currently running
    # script (eg. Given, When, Then)
    @skip.section = (msg) => @skip.sections 1, msg
    # gwt.skip.sections(1) # skip the current section
    @skip.sections = (count, msg) =>
      @statement_skip = Infinity
      @section_skip = count
    # gwt.skip.all() # terminate test run
    @skip.all = => @statement_skip = @section_skip = Infinity
    
    # list of files that are not bridge or gwt
    @artifacts = {}

  instrument: ->
    extract_scripts = (next) =>
      script_extractor @options, next
    read_scripts = (next) =>
      runner_file = @options.runner_file
      reader = line_reader.for_file runner_file, (line) =>
        return next() if not line?
        @all_scripts.push line
    load_tests = (next) =>
      @timer = timer pre: '# ', post: ''
      re = new RegExp(@options.sections ? '')
      scripts = (scr for scr in @all_scripts when re.test scr)
      
      @processed_scripts = {}
      do read_script = =>
        if not scripts.length
          @section(); return next()
        script = scripts.shift()
        return read_script() if not script
        @section script
        ext_name = path.extname(script)[1..]
        
        @pass_messages = []
        @artifacts[ext_name] ?= []
        @artifacts[ext_name].push script
        read_script()
    process_artifacts = (next) =>
      process_type = (ext, next) =>
        artifacts = @artifacts[ext]
        return next() if not artifacts?.length
        last = artifacts.pop()
        if last.indexOf('.gwt.') is -1
          artifacts.push last
        else
          artifacts.unshift last # put bridge at start
        do process_item = =>
          if not artifacts?.length
            delete @artifacts[ext] # only once
            return next()
          name = artifacts.shift()
          if proc = @file_processor[ext]
            (@context = proc).call gwt, name, process_item
          else
            @next()
      process_types = (exts..., next) =>
        do process_items = =>
          return next() if not exts.length
          process_type exts.shift(), process_items
      keys = (key for key, value of @artifacts)
      process_types 'coffee', keys..., next

    extract_scripts -> read_scripts -> load_tests ->
      process_artifacts -> gwt.go()
  # done with load as it has already created an instance
  load: -> @
 # add an actor to be run to create a test
  add: (title, test_list...) ->
    if typeof title is "string" then do ->
      actor = test_list[0]
      test_list[0] = ->
        console.log '#2 '+title
        actor.call gwt
    else test_list.unshift title
        
    for test in test_list
      @actions.push ->
         return @skip('', @statement_skip--) if @statement_skip
         test.call @, @
         @prompt @asking if @asking
      @test_count++
    return @

  # call to separate sections
  section: (name) ->
    @actions.push (gwt) =>
      return @next() if @actions.length is 1
      @section_skip -= 1 if @section_skip
      @statement_skip = 0 if not @section_skip
      name = /([^\/]+)\.[\w\.]+$/.
        exec(name)?[1].replace(/_/g, ' ')
      if name and not name.ends_with('.gwt') and
      not @sections_completed[name]
        @sections_completed[name] = true
        @print "#1 Section: #{name}"
      do func = =>
        return @next() unless @after_sections.length
        section = @after_sections.shift()
        try section(func) catch error
          console.error section.toString()
          throw error
      @timer.elapsed()
  sections_completed: {}

  test_statement: (statement) ->
    @title statement
    if not @ruler.run(statement)
      @fail """
             Unknown statement, add:
               gwt.rules(
                 /#{statement.replace(/\//g, '.')}/, () ->
                   @todo 'implement'
               )"""
  # called by instrumentation scripts to set up rules for gwt
  rules: (patterns...) ->
    @ruler.add(patterns...)
  # display a test line title
  title: (text) -> @print "#2    #{text}"
  # run code level tests
  code_tests: (code...) -> c.apply(@) for c in code

  # go to next script without marking pass or failure
  go: -> @next()
  next: ->
    if @test_count
      @print """
                  TAP version 13
                  1..#{@test_count}"""
      @count = -1
      @actions = [@preactions..., @actions...]
      @next = @next_next
      @passes_required = 0
      @next()
    else
      @print "# No tests"
      @exit()
  no_next: ->
  next_next: ->
    if not @actions.length
      clearTimeout @paused_timeout
      # all done - clean up
      @next = @no_next
      passes = @test_count - @failures - @skipped
      percent = Math.floor(passes * 100 / @test_count)
      @print "Failed #{@failures}/#{@test_count}, "+
        "#{@skipped} skipped, #{percent}% okay"
      @timer.total()
      @exit()
    @step_timer gwt.maximum_step_time ?
               @options.maximum_step_time
    @monitor_output = pass: null, fail: null, end: null
    try act.call(@, @) if act = @actions.shift()
    catch err then return @fail err.stack
    @asking = null
  step_timer: (seconds) ->
    clearTimeout @paused_timeout
    gwt.maximum_step_time = null
    overtime = =>
      @fail """
        gwt did not resume in #{seconds} seconds
        increase gwt.options.maximum_step_time before,
        or call gwt.step_timer(seconds) within the step"""
    @paused_timeout = setTimeout(overtime, seconds * 1000)
  # extend gwt with methods of interest to the current tests
  extend: (modules...) ->
    for ext in modules
      if ext instanceof Object
        for name, func of ext
          GWT::[name] = func
      else # a list of modules containing extensions
        ext = ext.replace /\s/g, '_'
        if ext[0] is '/'
          ext = path.join @options.script_path, ext
          ext = path.resolve ext
        if not @extensions[ext]
          @extend(@extensions[ext] = require ext)
  # all done ... clean up
  exit: ->
    do next_cleanup = =>
      return @finished = true if not @cleanups.length
      @cleanups.shift() next_cleanup
  cleanup: (cleanup) -> @cleanups.unshift cleanup

  files: -> @extend 'gwt/files'
  java: (options) ->
    @java = require 'gwt/java'
    @java(options)
  c: (options) ->
    @c = require 'gwt/c'
    @c(options)
  server: -> require 'gwt/server'
  browser: -> require 'gwt/browser'
  socket_server: -> require 'gwt/socket_server'
  process: (type) -> require('gwt/processes')(type)
  repl: (cmd, dir) -> @process().repl(cmd, dir)
  shell: (cmd) -> @process().shell(cmd)
  ask: (prompt) -> @extend 'gwt/interactive'; @ask prompt
  prompt: (prompt) -> @extend 'gwt/interactive'; @prompt prompt
      
module.exports =
  load: (@options) ->
    module.exports = global.gwt = gwt = new GWT @options
    gwt.extend 'gwt/tests', 'gwt/file_processor', 'gwt/io'
    require 'gwt/rules'
    gwt.instrument()
    return gwt
