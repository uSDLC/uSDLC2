gwt = require('gwt').instance()

tmpDir = os.tmpDir()

gwt /(\w+) operating system/, (all, system) -> gwt.required.os(system)
gwt /Internet access/, -> gwt.required.internet()
  
gwt /download '(.*)'/, all, url ->