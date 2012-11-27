gwt = module.parent.gwt
internet = require('Internet')(gwt)
instrument = require('Instrument')(gwt)
Processes = require('Processes')
path = require('path')

temp_uSDLC2_dir = ''

download_file_name = ''

gwt.rules(
  /(\w+) operating system/, (all, system) => instrument.os_required(system)
  /Internet access/, => internet.available()

  /download '(.*)'/, (all, href) =>
    download_file_name = internet.download href
  
  /downloaded file exists/, (all) =>
    instrument.file_exists download_file_name

  /run the downloaded bash script with parameters '(.*)'/, (all, args) =>
    instrument.in_directory temp_uSDLC2_dir, ->
      proc = Processes()
      proc.spawn '/bin/bash', download_file_name, args.split(' ')...

  /use a temporary directory ending in '(.*)'/, (all, path) =>
    temp_uSDLC2_dir = instrument.temporary_path('uSDLC2')
      
  /A temporary file '(.*)' exists/, (all, name) =>
    instrument.file_exists path.join temp_uSDLC2_dir, name
)