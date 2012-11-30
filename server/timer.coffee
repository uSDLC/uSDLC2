# Copyright (C) 2012,13 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license

class Timer # Use to report elapsed times
  # Timer = require 'timer'; timer = Timer() # creates a new instance and prints current date
  constructor: ->
    @start = @now = new Date()
    console.log "#{@now} <b>"
  # timer.elapsed() # will print seconds since start or last elapsed
  elapsed: ->
    time = Math.floor((new Date().getTime() - @now.getTime()) / 1000)
    console.log "#{@hms(time)} elapsed" if time > 0
    now = new Date()
  # timer.total() # will print seconds since timer was instantiated
  total: ->
    time = Math.floor((new Date().getTime() - @start.getTime()) / 1000)
    console.log "#{@hms(time)} seconds total <b>"
  # change seconds into hours, minutes and seconds
  hms: (time) ->
    seconds = time % 60
    time = Math.floor(time / 60)
    minutes = time % 60
    hours = Math.floor(time / 60)

    hours = if hours then "#{hours}:" else ''
    return "#{hours}#{minutes}:#{seconds}"

module.exports = -> new Timer()