# Copyright (C) 2013 paul@marrington.net, see GPL for license
gwt.rules(
  /Given a (shell|fork|spawn)/, (type) ->
    @process = @process(type); @pass()

  /response includes '(.*)'/, (included) ->
    @test @includes_text(included)

  /response matches \/(.*)\//, (re) ->
    @test @matches = @matches_text(re)
  
  /'(.*)' from above/, (title) ->
    re = new RegExp("/#{title.replace(/\W+/g, '.+')}\.gwt$")
    [actions,@actions] = [@actions,[]]
    scripts = (scr for scr in @all_scripts when re.test scr)
    return fail("no matching section") if not scripts.length
    @test_count -= 1
    @file_processor.gwt scripts[0], =>
      @actions.push actions...
      @next()
      
  /Ask '(.*)'/, (prompt) -> @ask prompt
)