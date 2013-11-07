# Copyright (C) 2013 paul@marrington.net, see GPL for license
EventEmitter = require('events').EventEmitter
path = require 'path'; timer = require 'common/timer'
dirs = require 'dirs'; line_reader = require 'line_reader'
steps = require 'steps'; Rules = require 'common/rules'
script_extractor = require 'script_extractor'
require 'common/strings'; queue = require 'queue'

require.extensions['.gwt.coffee'] =
  require.extensions['.coffee']
  
class GWT extends EventEmitter
  constructor: (@options) ->
    gwt = @
    # initialise important variables
    @options.document_path = path.join(
      @options.project, "usdlc2/#{@options.document}.html")
    @options.script_path =
      path.join(@options.project, @options.script_path)
    scripts = []; @actions = []; @test_count = 0
    @ruler = new Rules(@)
    @statement_skip = @section_skip = 0; @failures = 0
    @cleanups = []; @skipped = 0
    @after_sections = []; @paused_timeout = null
    @extensions = {}
    # first we take control of stdout and stderr
    @stdout = process.stdout.write
    @stderr = process.stderr.write
    @cleanups.push ->
      process.stdout.write = @stdout
      process.stderr.write = @stderr
    @output_array = []
    process.stdout.write = => @gwt_out arguments...
#     process.stderr.write = => @gwt_err arguments...
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
    @file_processor =
      'gwt': (script, next) ->
        reader = line_reader.for_file script, (statement) =>
          return if not statement?
          statement = statement.trim()
          if statement.length and statement[0] isnt '#'
            gwt.add (gwt) -> gwt.test_statement statement
        reader.on 'end', next
        
      'coffee': (script, next) ->
        parents = []
        last_slash = script.lastIndexOf('/')
        dot = script.indexOf('.', last_slash)
        base = '.'
        base = script[0..dot - 1] if dot > 0
        if script.ends_with('.gwt.coffee')
          ext_name = '.gwt.coffee'
          while base.length > 10 and
          base[-10..] isnt 'gen/usdlc2'
            parents.push(base)
            base = path.dirname(base)
        else
          parents = [base]
          
        do process = ->
          return next() if not parents.length
          script = parents.pop() + ext_name
          return process() if gwt.processed_scripts[script]
          gwt.processed_scripts[script] = script
          try
            script = path.resolve dirs.base(), script
            actor = require(script)
            if typeof actor is 'function'
              switch actor.length
                when 0 then gwt.add(actor) # direct
                when 1 then actor(gwt, process); return
                else actor(gwt) # synchronous
          catch err
            if err.code isnt 'MODULE_NOT_FOUND'
              console.log err.stack
          process()

    queue ->
      # 1: extract scripts from documentation (if newer)
      @queue -> script_extractor gwt.options, @next ->
      # 2: read a list of available scripts
      @queue ->
        runner_file = gwt.options.runner_file
        try
          reader = line_reader.for_file runner_file, (line) =>
            return @next() if not line?
            scripts.push line
        catch e
          @next(@error)
      # 3: load tests - either gwt or explicitly in coffee
      @queue ->
        gwt.timer = timer pre: '# ', post: ''
        re = new RegExp(gwt.options.sections ? '')
        scripts = (scr for scr in scripts when re.test scr)
        gwt.processed_scripts = {}
        do read_script = =>
          if not scripts.length
            gwt.section(); return @next()
          script = scripts.shift()
          return read_script() if not script
          gwt.section script
          ext_name = path.extname(script)[1..]
          
          gwt.tests = queue ->
          gwt.queue = (self..., step) =>
            gwt.tests.queue =>
              gwt.tests.maximum_time_seconds =
                gwt.options.maximum_step_time
              gwt.self = self[0] ? gwt
              (@context = step).apply(gwt)
          gwt.pass_messages = []
          
          gwt.artifacts[ext_name] ?= []
          gwt.artifacts[ext_name].push script
          read_script()
      # 4: process known artifacts
      @queue ->
        process_type = (ext, next) =>
          artifacts = gwt.artifacts[ext]
          do process_item = =>
            if not artifacts?.length
              delete gwt.artifacts[ext] # only once
              return next()
            name = artifacts.shift()
            if proc = gwt.file_processor[ext]
              (@context = proc).call gwt, name, process_item
            else
              console.error "Unknown file type for #{name}"
              @abort()
              gwt.next()
        process_types = (exts..., next) =>
          do process_items = =>
            return next() if not exts.length
            process_type exts.shift(), process_items
        keys = (key for key, value of gwt.artifacts)
        process_types 'coffee', keys..., @next ->
      # 5: run the tests
      @queue -> gwt.go(); @next()
  # done with load as it has already created an instance
  load: -> @
  # Code under test output control and display
  gwt_out: (chunk, encoding, fd) ->
    @output_array.push chunk
    @stdout.call process.stdout, chunk, encoding, fd
    @monitor chunk
  gwt_err: (chunk, encoding, fd) ->
    chunk = chunk.toString()
    ls = ('#!! '+l for l in chunk.split('\n') when l.length)
    @gwt_out ls.join('\n'), encoding, fd
  output: -> (output_array = [@output_array.join('')])[0]
  # Checking test output for telling signs
  monitor_output: pass: null, fail: null, end: null
  monitor: (chunk) ->
    # there is a small chance this will fail if the chunk
    # does not break on a line boundary
    for line in chunk.toString().split('\n')
      return @pass() if @monitor_output.pass?.test line
      return @fail() if @monitor_output.fail?.test line
  # add an actor to be run to create a test
  add: (test_list...) ->
    for test in test_list
      @actions.push test
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
      if name and not name.ends_with('.gwt')
        console.log "#1 Section: #{name}"
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
                 /#{statement.replace(/\//g, '.')}/, () ->
                   @todo 'implement'
               )"""
  # called by instrumentation scripts to set up rules for gwt
  rules: (patterns...) ->
    @ruler.add(patterns...)
  # display a test line title
  title: (text) -> console.log "#2    #{text}"
  # run code level tests
  code_tests: (code...) -> c.apply(@) for c in code

  # go to next script without marking pass or failure
  go: -> @next()
  next: ->
    if @test_count
      console.log """
                  TAP version 13
                  1..#{@test_count}"""
      @count = 0
      @next = @next_next
      @next()
    else
      console.log "# No tests"
      @exit()
  no_next: ->
  next_next: ->
    clearTimeout @paused_timeout
    if not @actions.length
      # all done - clean up
      @next = @no_next
      passes = @test_count - @failures - @skipped
      percent = Math.floor(passes * 100 / @test_count)
      console.log "Failed #{@failures}/#{@test_count}, "+
        "#{@skipped} skipped, #{percent}% okay"
      @timer.total()
      @exit()
    max_time = @options.maximum_step_time
    overtime = =>
      @fail """
        gwt did not resume in #{max_time} seconds
        increase gwt.options.maximum_step_time (seconds)
        if needed"""
    @paused_timeout = setTimeout(overtime, max_time * 1000)
    try act.call(gwt, gwt) if act = @actions.shift()
    catch err then return @fail err
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
      cleanup = @cleanups.shift()
      steps(cleanup, next_cleanup)

  files: -> gwt.extend 'gwt/files'
  java: (options) ->
    @java = require 'gwt/java'
    @java(options)
  server: -> @server = require 'gwt/server'
  process: (type) ->
    require('gwt/processes')(type, @options.project)
  repl: (cmd, dir) -> @process().repl(cmd, dir)
      
module.exports =
  load: (@options) ->
    module.exports = global.gwt = gwt = new GWT @options
    gwt.extend 'gwt/base'
    require 'gwt/rules'
    return gwt
