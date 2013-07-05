# Copyright (C) 2012,13 paul@marrington.net, see GPL for license
Sax = require 'sax'; fs = require 'fs'; path = require 'path'
mkdirs = require('dirs').mkdirsSync
newer = require 'newer'; steps = require 'steps'

module.exports = (options, next) ->
  options.runner_file =
    path.join options.project, "gen/usdlc2/#{options.document}.list"

  return next() if newer(options.runner_file, options.document_path)

  script_content = null; script_name = ''
  depth = 0; in_heading = false; headings = []

  sax = new Sax()

  sax.on 'opening_tag', (name, attributes...) ->
    if in_heading
      headings[depth] += "<#{name} #{attributes.join(' ')}>"
    else if name[0] is 'h' and not isNaN(depth = +name[1])
      in_heading = true
      headings[headings.length = --depth] = ''
    else if (name is 'pre' or name is 'textarea')
      for attr in attributes
        if attr[0..4] is 'type='
          script_content = []
          script_name = "#{path.join headings...}.#{attr[6..-2]}"
          script_name = script_name.replace(/(\s+|(&nbsp;)+)/g, '_')
          script_name = path.join options.project, 'gen/usdlc2', script_name
          break

  sax.on 'text', (text) ->
    headings[depth] += text if in_heading
    script_content.push(text) if script_content?

  sax.on 'closing_tag', (name) ->
    in_heading = false if name[0] is 'h'
    headings[depth] += "</#{name}>" if in_heading
    if (name is 'pre' or name is 'textarea') and script_content?
      console.log "#: Build #{script_name}"
      mkdirs path.dirname script_name
      fs.appendFile options.runner_file, "#{script_name}\n"
      steps(
        ->  @requires 'ent'
        ->  @content = @ent.decode script_content.join '\n'
        ->  script_content = null
        ->  fs.writeFile script_name, @content, @next
      )

  sax.on 'finish', next

  fs.unlink options.runner_file, ->
    input_path = path.join options.project, "usdlc2/#{options.document}.html"
    fs.createReadStream(input_path).pipe(sax)
