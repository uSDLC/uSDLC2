# Copyright (C) 2012,13 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license

# This script expects a base directory, query string, hash
# It will run Setup.coffee from the base directory, then process each statement.
# Everything is anynchronous and output goes to stdout / stderr.
path = require 'path'; os = require 'os'; fs = require 'fs'; timer = require 'timer'
http = require 'http'; Line_Reader = require 'Line-Reader'

class GWT extends require('stream').Stream
  # new GWT().base_directory(dir).rules(list).scripts(script...)
  constructor: () ->
    @files = []
    @patterns = []
    @processing = false
    @paused = false
    @timer = timer() # date-stamp and timing
    
  base_directory: (@dir) -> return this
  rules: (patterns...) -> @patterns = @patterns.concat(patterns); return this
  
  # Do the grunt work of reading and processing statements from a list of script files
  scripts: (files...) ->
    @files = @files.concat files
    @process_file() if not @processing
    return this
    
  process_file: ->
    return if @paused
    if not @files.length
      @timer.total()
      @emit 'end'
      return @processing = false
    @processing = true
    name = @files.shift()
    @timer.elapsed()
    console.log ">>#{name.split('_')[0]}"
    file = "#{path.join dir, name}.gwt"
    @reader = Line_Reader(fs.createReadStream(file))
    @reader.on 'data', (statement) =>
      # Look for a matching statement, then process the action
      for pattern, index in @patterns by 2
        if match = pattern.exec(statement)
          console.log ">>> #{statement}"
          return @patterns[index + 1](match...)
      throw """Unknown statement, add:
        ```
        gwt = module.gwt = module.parent.gwt
        require '../Setup'
        gwt.rules(
          /#{statement.replace(/\//g, '.')}/, (all) =>
            throw 'not implemented'
        )
        ```"""
    # finished with this file - on ot the next
    @reader.on 'end', =>
      @reader.destroy(); 
      @reader = null
      @process_file()
  
  # Pause the GWT loop - probably because the resume is part of a callback
  pause: -> @paused = true; @reader.pause()
  
  # Resume a previously paused GWT loop - in asynchronous callback
  resume: ->
    @paused = false;
    if @reader then @reader.resume() else @process_file()
  
  # Terminate the test. This is not a failure, just lacking preconditions
  destroy: -> 
    @files = [] # so no more files will be processed
    @reader.destroy() # so current reader won't pick up any more lines
 
# This script expects a base directory followed by statement script names.
querystring = require 'querystring'
console.log "[run | #{process.argv.join(' ')}]"
[url_path, query, hash] = process.argv[2..]
dir = path.dirname(url_path)
scripts = querystring.parse(query).scripts.split(',')

# process statements from all specified scripts - starting with Setup.coffee
gwt = new GWT().base_directory(dir)
# It will run Setup.coffee from the base directory - module.parent.gwt(pattern,action,...)
module.gwt = gwt
require(path.join(dir, 'Setup'))
# then process each statement.
gwt.scripts(scripts...)
# When all is done gwt will emit 'end' - and we can terminate the process/script
gwt.on 'end', -> process.exit(0)
