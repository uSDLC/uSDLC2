# Copyright (C) 2014 paul@marrington.net, see GPL for license

module.exports =
  # Code under test output control and display
  gwt_out: (chunk, encoding, fd) ->
    @output_array.push chunk
    @stdout.call process.stdout, chunk, encoding, fd
    @monitor chunk
  gwt_err: (chunk, encoding, fd) ->
    chunk = chunk.toString()
    ls = ('#!! '+l for l in chunk.split('\n') when l.length)
    @gwt_out ls.join('\n') + '\n', encoding, fd
  output: -> (@output_array = [@output_array.join('')])[0]
  clear_output: -> @output_array = []
  # Checking test output for telling signs
  monitor_output: pass: null, fail: null, end: null
  expect: (pass,fail,end) ->
    re = (re) ->
      return new RegExp(re) if typeof re is "string"
      return re
    @monitor_output.pass = re(pass) if pass
    @monitor_output.fail = re(fail) if fail
    @monitor_output.end = re(end) if end
  monitor: (chunk) ->
    # there is a small chance this will fail if the chunk
    # does not break on a line boundary
    for line in chunk.toString().split('\n')
      return @pass() if @monitor_output.pass?.test line
      return @fail() if @monitor_output.fail?.test line