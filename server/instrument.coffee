# Copyright (C) 2012,13 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license
fs = require 'fs'; os = require 'os'

class Instrument
  constructor: (@stream) ->
    
  os_required: (system) ->
    runningOn = os.type().toLowerCase()
    system = system.toLowerCase()
    return true if system is runningOn or system is 'unix' and runningOn isnt 'windows'
    @stream.destroy()
    return false
    
  file_exists: (name, pattern) ->
    @stream.pause()
    fs.stat name, (error, data) =>
      throw error if error
      @stream.resume()

  file_contains: (name, pattern) ->
    @stream.pause()
    fs.readFile name, 'utf8', (error, data) =>
      throw error if error
      match = new RegExp(pattern).exec(data)
      throw "No match for #{pattern}" if match.length is 0
      @stream.resume()

module.exports = (stream) -> new Instrument(stream)
