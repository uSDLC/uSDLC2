# Copyright (C) 2012,13 paul@marrington.net, see /GPL license
Sax = require 'sax'; fs = require 'fs'; path = require 'path'
dirs = require('dirs'); newer = require 'newer'
npm = require 'npm'; streams = require 'streams'

decode = null

module.exports = (options, extraction_complete) ->
  gen = path.join options.project, "gen/usdlc2"
  options.runner_file =
    path.join gen, "#{options.document}.list"
  input_path = path.join(
    options.project, "usdlc2/#{options.document}.html")

  if newer(options.runner_file, options.document_path)
    return extraction_complete()
  
  script_content = null; script_name = ''
  depth = 0; in_heading = false; headings = []

  sax = new Sax()

  sax.on 'opening_tag', (name, attributes..., next) ->
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
          script_name = script_name.replace(
            /(&nbsp;|&quot;|[\s"'\(\)\*\+\^\$\?\\:;,])+/g, '_')
          script_name = path.join gen, script_name
          break
    else if script_content? and name is 'br'
      script_content.push('\n')
    next()

  sax.on 'text', (text) ->
    headings[depth] += text if in_heading
    script_content.push(text) if script_content?
    
  added_to_runner = {}
  add_to_runner = (script_name, next) ->
    return next() if added_to_runner[script_name]
    added_to_runner[script_name] = script_name
    fs.appendFile options.runner_file, "#{script_name}\n", next

  sax.on 'closing_tag', (name, next) ->
    in_heading = false if name[0] is 'h'
    headings[depth] += "</#{name}>" if in_heading
    return next() if not (name in ['pre','textarea']) or not script_content?
    console.log "#: Build #{script_name}"
    content = decode script_content.join ''
    script_content = null
    dirs.mkdirs path.dirname(script_name), ->
      fs.appendFile script_name, content, ->
        add_to_runner script_name, next

  sax.on 'finish', extraction_complete

  npm 'ent', (err, ent) ->
    throw err if err
    decode = ent.decode
    dirs.rmdirs gen, ->
      streams.pipe fs.createReadStream(input_path), sax, ->
