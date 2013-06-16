# Copyright (C) 2013 paul@marrington.net, see GPL for license

gwt.rules(
  /Given a (shell|fork|spawn)/, (type) -> @process = gwt.processes(type)
    
  /response includes '(.*)'/, (included) -> gwt.includes_text(included)
)