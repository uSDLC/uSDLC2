gwt = global.gwt
Processes = require('Processes')
fs = require 'file-system'

proc = null
dir = ''

gwt.rules(
  /(.*) as current directory/, (all, cwd) => dir = cwd
  
  /run '(.*)'$/,
    (all, command_line) =>
      gwt.pause()
      fs.in_directory dir, =>
        [program, args...] = command_line.split ' '
        proc = Processes()
        proc.spawn program, args, =>
          gwt.resume()
      
  /return code is (\d+)$/,
    (all, code) => 
      throw "return code is #{proc.code}, not #{code}" if +code isnt +proc.code
)