# Copyright (C) 2014 paul@marrington.net, see GPL for license

module.exports =
  ask: (prompt) ->
    @asking = prompt
  prompt: (text) ->
    @print "#ask #{text}"
    return @skip('not interactive') if not @options.host
    @step_timer(600000)
    # otherwise wait for response from browser