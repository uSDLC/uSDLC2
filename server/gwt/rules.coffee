# Copyright (C) 2013-5 paul@marrington.net, see GPL for license
gwt.rules(
  /Given a (shell|fork|spawn)/, (type) ->
    @process = @process(type); @pass()

  /response includes '(.*)'/, (included) ->
    @test @includes_text(included)

  /response matches \/(.*)\//, (re) ->
    @test @matches = @matches_text(re)
  
  /'(.*)' from (above|below)/, (title) ->
    re = new RegExp("/#{title.replace(/\W+/g, '.+')}")
    [actions,@actions] = [@actions,[]]
    scripts = (scr for scr in @all_scripts when re.test scr)
    return fail("no matching section") if not scripts.length
    @test_count -= 1
    artifacts = @collect_artifacts_from scripts
    @process_artifacts artifacts, =>
      @actions.push actions...
      @next()
      
  /[Aa]sk '(.*)'/, (prompt) -> @ask prompt; @pass()
  /[Pp]rompt '(.*)'/, (prompt) -> @prompt prompt
  /[Ee]xpect '(.*)'/, (re) -> @expect re
)