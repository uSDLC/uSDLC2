# Copyright (C) 2012,13 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license
os = require('os')

Class GWT

  # Constructor prepares GWT for action
  constructor: ->
  
  # Pause the GWT loop - probably because the resume is part of a callback
  pause: ->
  
  # Resume a previously paused GWT loop - in asynchronous callback
  resume: ->
  
  # Terminate the test. This is not a failure, just lacking preconditions
  terminate: ->

  # Environmental factors required for gwt to happen - otherwise aborts silently
  required:
    internet: ->
	    http = require 'http'
	    @pause()
	    http.request({host: 'google.com', method: 'HEAD'}, (response) ->
	      if response.statusCode is 200
	        @resume()
	      else
	        @terminate()
	    ).on 'error', -> @terminate()
    os: (system) ->
      runningOn = os.type().toLowerCase()
      system = system.toLowerCase()
      return true if system is runningOn or system is 'unix and runningOn isnt 'windows'
      @terminate()
      return false

    
module.exports = () -> new GWT()
