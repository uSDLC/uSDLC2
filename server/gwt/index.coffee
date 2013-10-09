# Copyright (C) 2013 paul@marrington.net, see GPL for license
EventEmitter = require('events').EventEmitter
path = require 'path'; timer = require 'common/timer'
dirs = require 'dirs'; line_reader = require 'line_reader'
steps = require 'steps'; Rules = require 'common/rules'
script_extractor = require 'script_extractor'
require 'common/strings'; queue = steps.queue

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
    scripts = []; @actions = []; @tests = 0
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

    queue ->
      # 1: extract scripts from documentation (if newer)
      @queue (next) -> script_extractor gwt.options, next
      # 2: read a list of available scripts
      @queue (next) ->
        runner_file = gwt.options.runner_file
        try
          reader = line_reader.for_file runner_file, (line) =>
            scripts.push line if line?
          reader.on 'end', next
        catch e
          next()
      # 3: load tests - either gwt or explicitly in coffee
      @queue (next) ->
        gwt.timer = timer pre: '# ', post: ''
        re = new RegExp(gwt.options.sections ? '')
        scripts = (scr for scr in scripts when re.test scr)
        processed_scripts = {}
        do read_script = =>
          if not scripts.length
            gwt.section(); return next()
          script = scripts.shift()
          return read_script() if not script
          gwt.section script
          ext_name = path.extname(script)
          switch ext_name
            when '.gwt'
              reader = line_reader.for_file script,
              (statement) =>
                if statement?
                  statement = statement.trim()
                  if statement.length and statement[0] isnt '#'
                    gwt.add (gwt) ->
                      gwt.test_statement statement
              reader.on 'end', read_script
            when '.coffee'
              parents = []
              dot = script.indexOf('.', script.lastIndexOf('/'))
              base = if dot > 0 then script[0..dot - 1] else '.'
              if script.ends_with('.gwt.coffee')
                ext_name = '.gwt.coffee'
                while base.length > 10 and
                base[-10..] isnt 'gen/usdlc2'
                  parents.push(base)
                  base = path.dirname(base)
              else
                parents = [base]
                
              do process = ->
                return read_script() if not parents.length
                script = parents.pop() + ext_name
                return process() if processed_scripts[script]
                processed_scripts[script] = script
                try
                  actor =
                    require(path.resolve dirs.base(), script)
                  if typeof actor is 'function'
                    switch actor.length
                      when 0 then gwt.add(actor) # direct
                      when 1 then actor(gwt, process); return
                      else actor(gwt) # synchronous
                catch err
                process()
      # 4: run the tests
      @queue -> gwt.go()
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
    @steps = steps(@)
    @steps.all_asynchronous = true
    @queue = (self..., step) =>
      @steps.queue =>
        @steps.long_operation(gwt.options.maximum_step_time)
        gwt.self = self[0] ? gwt
        step.apply(gwt)
    @pass_messages = []
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
    max_time = @options.maximum_step_time
    overtime = =>
      @fail """
        gwt did not resume in #{max_time} seconds
        increase gwt.options.maximum_step_time (seconds)
        if needed"""
    @paused_timeout = setTimeout(overtime, max_time * 1000)
    try
      action = @actions.shift()
      return action(gwt) if @actions.length
    catch err
      return @fail err
    # all done - clean up
    clearTimeout @paused_timeout
    passes = @tests - @failures - @skipped
    percent = Math.floor(passes * 100 / @tests)
    console.log "Failed #{@failures}/#{@tests}, "+
      "#{@skipped} skipped, #{percent}% okay"
    @timer.total()
    @exit()
  # extend gwt with methods of interest to the current tests
  extend: (modules...) ->
    for extension in modules
      if extension instanceof Object
        for name, func of extension
          GWT.prototype[name] = func
      else # a list of modules containing extensions
        extension = extension.replace /\s/g, '_'
        if extension[0] is '/'
          extension = path.join @options.script_path, extension
          extension = path.resolve extension
        if not @extensions[extension]
          @extend(@extensions[extension] = require extension)
  # all done ... clean up
  exit: ->
    do next_cleanup = =>
      return if not @cleanups.length
      cleanup = @cleanups.shift()
      steps(cleanup, next_cleanup)

  files: -> gwt.extend 'gwt/files'
  server: -> @server = require 'gwt/server'
  process: (type) -> require('gwt/processes')(type)

module.exports =
  load: (@options) ->
    module.exports = global.gwt = gwt = new GWT @options
    gwt.extend 'gwt/base'
    require 'gwt/rules'
    return gwt
