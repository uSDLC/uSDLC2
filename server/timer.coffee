# Copyright (C) 2012,13 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license


class Timer # Use to report elapsed times
  # Timer = require 'timer'; timer = Timer() # creates a new instance and prints current date
  constructor: ->
    @start = @now = new Date()
    console.log "~~#{@now}"
  # timer.elapsed() # will print seconds since start or last elapsed
  elapsed: ->
    time = Math.floor((new Date().getTime() - @now.getTime()) / 1000)
    console.log "~~#{time} seconds elapsed" if time > 0
    now = new Date()
  # timer.total() # will print seconds since timer was instantiated
  total: ->
    time = Math.floor((new Date().getTime() - @start.getTime()) / 1000)
    console.log "~~#{time} seconds total"
module.exports = -> new Timer()