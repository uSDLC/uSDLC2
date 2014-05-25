# Copyright (C) 2014 paul@marrington.net, see GPL for license

module.exports =
  ask: (prompt) ->
    @step_timer(600000)
    @print "#p #{prompt}"
    return @skip('not interactive') if not @options.host
    # otherwise wait for response from browser