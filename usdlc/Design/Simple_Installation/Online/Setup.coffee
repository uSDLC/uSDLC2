gwt = module.parent.gwt
internet = require('Internet')(gwt)
instrument = require('Instrument')(gwt)

process.download_file_name = ''

gwt.rules(
  /(\w+) operating system/, (all, system) => instrument.os_required(system)
  /Internet access/, => internet.available()

  /download '(.*)'/, (all, href) =>
    process.download_file_name = internet.download href
  
  /downloaded file exists/, (all) =>
    instrument.file_exists process.download_file_name
)