# Copyright (C) 2012,13 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license
fs = require 'fs'; os = require 'os'; path = require 'path'; child = require 'child_process'

class Instrument  # instrument = require('instrument')(gwt)
  constructor: (@gwt) ->
  
  # some scripts are platform dependent - so terminates without an error
  os_required: (system) -> # instrument.os_required('windows|unix|darwin|linux')
    runningOn = os.type().toLowerCase()
    system = system.toLowerCase()
    return true if system is runningOn or system is 'unix' and runningOn isnt 'windows'
    @gwt.skip.section()
    return false
    
  # instrument.file_exists name, (exists, next) -> # default next is to throw on error
  file_exists: (name, next = (exists, later) -> throw "no file #{name}" if not exists; later()) ->
    @gwt.pause()
    fs.stat name, (error, data) => next(not error, => @gwt.resume())

  # look in a file for a matching regular expression. Raise an error if it is not found.
  file_contains: (name, pattern) ->
    @gwt.pause()
    fs.readFile name, 'utf8', (error, data) =>
      throw error if error
      match = new RegExp(pattern).exec(data)
      throw "No match for #{pattern}" if match.length is 0
      @gwt.resume()
      
  # return a path in the temp directory - allowing one more level down in 'ending'
  temporary_path: (ending, next = (later) -> later()) ->
    @gwt.pause()
    dir = path.join os.tmpDir(), ending
    fs.mkdir dir, => next(=> @gwt.resume())
    return dir
    
  # run a function with current working directory set - then set back afterwards
  in_directory: (to, action) ->
    cwd = process.cwd()
    try
      process.chdir(to)
      action()
    finally
      process.chdir(cwd)

module.exports = (stream) -> new Instrument(stream)
