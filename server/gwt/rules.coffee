# Copyright (C) 2013 paul@marrington.net, see GPL for license
gwt.rules(
  /Given a (shell|fork|spawn)/, (type) ->
    @process = gwt.process(type); @pass()

  /response includes '(.*)'/, (included) ->
    @test gwt.includes_text(included)

  /response matches \/(.*)\//, (re) ->
    @test @matches = gwt.matches_text(re)
)