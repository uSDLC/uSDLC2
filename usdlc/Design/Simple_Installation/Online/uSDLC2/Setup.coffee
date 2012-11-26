gwt = module.gwt = module.parent.gwt
require '../Setup'

instrument = require('Instrument')(gwt)
proc = require('Processes')()
path = require('path')

temp_uSDLC2_dir = ''

gwt.rules(
  /use a temporary directory ending in '(.*)'/, (all, path) =>
    temp_uSDLC2_dir = instrument.temporary_path('uSDLC2')

  /run the downloaded bash script with parameters '(.*)'/, (all, args) =>
    instrument.in_directory temp_uSDLC2_dir, ->
      proc.spawn '/bin/bash', process.download_file_name, args.split(' ')...
      
  /A temporary file '(.*)' exists/, (all, name) =>
    instrument.file_exists path.join temp_uSDLC2_dir, name
)