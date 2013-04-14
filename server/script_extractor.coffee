# Copyright (C) 2012,13 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license
Parser = require 'html_parser'; fs = require 'fs'; path = require 'path'
EventEmitter = require('events').EventEmitter; mkdirs = require('dirs').mkdirsSync
newer = require 'newer'; steps = require 'steps'

module.exports = (options, next) ->
  options.runner_file =
    path.join options.project, "gen/usdlc2/#{options.document}.list"
  processor_depth = 0

  return next() if newer options.runner_file, options.document_path

  script_content = null; script_name = ''; parse_complete = false
  depth = 0; in_heading = false; headings = [options.document]
  Parser (parser) ->
    parser.on 'open', (name, attributes) ->
      if in_heading
        attr = ("#{key}=#{value}" for key, value of attributes).join(' ')
        headings[depth] += "<#{name} #{attr}>"
      else if name[0] is 'h'
        in_heading = true
        depth = +name[1]
        depth = 0 if attributes.id is 'page_title'
        headings[headings.length = depth] = ''
      else if name is 'pre' and attributes.type
        script_content = []
        script_name = "#{path.join headings...}.#{attributes.type}"
        script_name = script_name.replace(/\s+/g, '_')
        script_name = path.join options.project, 'gen/usdlc2', script_name

    parser.on 'text', (text) ->
      headings[depth] += text if in_heading
      script_content.push(text) if script_content?

    parser.on 'close', (name) ->
      in_heading = false if name[0] is 'h'
      headings[depth] += "</#{name}>" if in_heading
      if name is 'pre' and script_content?
        console.log script_name
        mkdirs path.dirname script_name
        fs.appendFile options.runner_file, "#{script_name}\n"
        processor_depth++
        steps(
          ->  @script_content = script_content
          ->  @requires 'ent'
          ->  @content = @ent.decode @script_content.join '\n'
          ->  @script_content = null
          ->  fs.writeFile script_name, @content, @next
          ->  next() if not --processor_depth and parse_complete
        )

    parser.on 'end', ->
      parse_complete = true
      next() if not processor_depth

    fs.unlink options.runner_file, ->
      parser.file path.join options.project, "usdlc2/#{options.document}.html"
