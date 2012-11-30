gwt = global.gwt

internet = require('Internet')(gwt)
instrument = require('Instrument')(gwt)
Processes = require('Processes')
path = require('path'); os = require('os')

file_name = ''
temp_directory = ''
file_path = -> path.join temp_directory, file_name

gwt.rules(
  /(\w+) operating system/, (all, system) => instrument.os_required(system)
  /Internet access/, => internet.available()
  
  /working with a file called '(.*)'/, (all, name) => file_name = name
  
  /in a temporary directory ending in '(.*)'/, (all, ending) =>
    temp_directory = instrument.temporary_path(ending)
    
  /download from github project '(.*)' at '(.*)'/, (all, project, at) =>
    internet.download.to(file_path()).
      from("https://raw.github.com/#{project}/#{at}/#{file_name}")
  
  /file exists/, (all) =>
    instrument.file_exists file_path()
    
  /run '(.*)'/, (all, command_line) =>
    instrument.in_directory temp_directory, =>
      proc = Processes().stream(gwt)
      [program, args...] = command_line.split ' '
      proc.spawn program, args
      
  /if the file does not exist/, (all) =>
    instrument.file_exists file_path(), (exists, next) =>
      gwt.skip.statements() if exists
      next()
      
  /and confirm a file '(.*)' now exists/, (all, name) =>
    instrument.file_exists path.join temp_directory, name
    
  /download from github project '(.*)'/, (all, project) =>
    projectName = project.split('/').pop()
    temp_directory = instrument.temporary_path projectName, (next) =>
      old_file_name = file_name
      file_name = 'install-usdlc-on-unix.sh'
      at = 'master/release'
      internet.download.to(file_path()).
      from "https://raw.github.com/#{project}/#{at}/#{file_name}", (next2) =>
        instrument.in_directory temp_directory, =>
          proc = Processes()
          proc.spawn '/bin/bash', [file_path(), '.', 'no-go'], =>
            file_name = old_file_name
            next2(next)
)