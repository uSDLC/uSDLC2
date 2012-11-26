# Copyright (C) 2012,13 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license
fs = require 'fs'; os = require 'os'; path = require 'path'; child = require 'child_process'


class Instrument  # instrument = require('instrument')(gwt)
  constructor: (@stream) ->
  
  # some scripts are platform dependent - so terminates without an error
  os_required: (system) -> # instrument.os_required('windows|unix|darwin|linux')
    runningOn = os.type().toLowerCase()
    system = system.toLowerCase()
    return true if system is runningOn or system is 'unix' and runningOn isnt 'windows'
    @stream.destroy()
    return false
    
  # see if a file exists - raising an error if it doesn't
  file_exists: (name) ->
    @stream.pause()
    fs.stat name, (error, data) =>
      throw error if error
      @stream.resume()

  # look in a file for a matching regular expression. Raise an error if it is not found.
  file_contains: (name, pattern) ->
    @stream.pause()
    fs.readFile name, 'utf8', (error, data) =>
      throw error if error
      match = new RegExp(pattern).exec(data)
      throw "No match for #{pattern}" if match.length is 0
      @stream.resume()
      
  # return a path in the temp directory - allowing one more level down in 'ending'
  temporary_path: (ending) ->
    @stream.pause()
    dir = path.join os.tmpDir(), ending
    fs.mkdir dir, => @stream.resume()
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
