# Copyright (C) 2013 paul@marrington.net, see GPL for license
EventEmitter = require('events').EventEmitter
path = require 'path'; timer = require 'common/timer'
dirs = require 'dirs'; line_reader = require 'line_reader'
Rules = require 'common/rules'
script_extractor = require 'script_extractor'
require 'common/strings'

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
    scripts = []; @preactions = []
    @actions = []; @test_count = 0
    @ruler = new Rules(@)
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
        base = script[0..dot - 1]
        if script.ends_with('.gwt.coffee')
          ext_name = '.gwt.coffee'
          while base.length > 10 and
          base[-10..] isnt 'gen/usdlc2'
            parents.push(base)
            base = path.dirname(base)
        else
          ext_name = script[dot..]
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
              if not actor.length
                gwt.add actor
              else
                actor.call(gwt, process); return
          catch err
            if (err.code isnt 'MODULE_NOT_FOUND') or
            (err.message.indexOf(script) == -1)
              console.log err.stack
          process()

    extract_scripts = (next) ->
      script_extractor gwt.options, next
    read_scripts = (next) ->
      runner_file = gwt.options.runner_file
      reader = line_reader.for_file runner_file, (line) =>
        return next() if not line?
        scripts.push line
    load_tests = (next) ->
      gwt.timer = timer pre: '# ', post: ''
      re = new RegExp(gwt.options.sections ? '')
      scripts = (scr for scr in scripts when re.test scr)
      gwt.processed_scripts = {}
      do read_script = =>
        if not scripts.length
          gwt.section(); return next()
        script = scripts.shift()
        return read_script() if not script
        gwt.section script
        ext_name = path.extname(script)[1..]
        
        gwt.pass_messages = []
        gwt.artifacts[ext_name] ?= []
        gwt.artifacts[ext_name].push script
        read_script()
    process_artifacts = (next) ->
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
            gwt.next()
      process_types = (exts..., next) =>
        do process_items = =>
          return next() if not exts.length
          process_type exts.shift(), process_items
      keys = (key for key, value of gwt.artifacts)
      process_types 'coffee', keys..., next

    extract_scripts -> read_scripts -> load_tests ->
      process_artifacts -> gwt.go()
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
    @gwt_out ls.join('\n') + '\n', encoding, fd
  output: -> (@output_array = [@output_array.join('')])[0]
  clear_output: -> @output_array = []
  # Checking test output for telling signs
  monitor_output: pass: null, fail: null, end: null
  expect: (pass,fail,end) ->
    re = (re) ->
      return new RegExp(re) if typeof re is "string"
      return re
    @monitor_output.pass = re(pass) if pass
    @monitor_output.fail = re(fail) if fail
    @monitor_output.end = re(end) if end
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
      if name and not name.ends_with('.gwt') and
      not @sections_completed[name]
        @sections_completed[name] = true
        console.log "#1 Section: #{name}"
      do func = =>
        return @next() unless @after_sections.length
        section = @after_sections.shift()
        try section(func) catch error
          console.log section.toString()
          throw error
      @timer.elapsed()
  sections_completed: {}

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
      @actions = [@preactions..., @actions...]
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
        increase gwt.options.maximum_step_time (seconds)"""
    @paused_timeout = setTimeout(overtime, max_time * 1000)
    try act.call(gwt, gwt) if act = @actions.shift()
    catch err then return @fail err.stack
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

  files: -> gwt.extend 'gwt/files'
  java: (options) ->
    @java = require 'gwt/java'
    @java(options)
  c: (options) ->
    @c = require 'gwt/c'
    @c(options)
  server: -> require 'gwt/server'
  browser: -> require 'gwt/browser'
  socket_server: -> require 'gwt/socket_server'
  process: (type) ->
    require('gwt/processes')(type, @options.project)
  repl: (cmd, dir) -> @process().repl(cmd, dir)
  shell: (cmd) -> @process().shell(cmd)
      
module.exports =
  load: (@options) ->
    module.exports = global.gwt = gwt = new GWT @options
    gwt.extend 'gwt/base'
    require 'gwt/rules'
    return gwt
