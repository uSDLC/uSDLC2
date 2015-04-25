#!/bin/bash
line_reader = require 'line_reader'
require 'common/strings'; path = require 'path'
dirs = require 'dirs'

module.exports = file_processor:
  'gwt': (script, next) ->
    accumulator = []
    reader = line_reader.for_file script, (statement) =>
      return next() if not statement? # EOF
      statement = statement.trim()
      if statement.length and statement[0] isnt '#'
        if statement.ends_with('\\')
          accumulator.push statement[0..-2].trim()+' '
        else
          statement = accumulator.join('') + statement
          accumulator = []
          gwt.add (gwt) ->
            gwt.test_statement statement

  'coffee': (script, next) ->
    parents = []
    script = dirs.normalise script
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
        actor = require(script)
        if typeof actor is 'function'
          if not actor.length and not actor.name.length
            gwt.add actor # no params and not prototype
      catch err
        if (err.code isnt 'MODULE_NOT_FOUND') or
        (err.message.indexOf(script) == -1)
          console.log err.stack
      process()