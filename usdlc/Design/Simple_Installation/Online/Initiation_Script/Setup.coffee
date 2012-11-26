gwt = module.parent.gwt
internet = require('internet')(gwt)
instrument = require('instrument')(gwt)

download_file_name = ''

gwt.rules(
  /(\w+) operating system/, (all, system) => instrument.os_required(system)
  /Internet access/, => internet.available()

  /download '(.*)'/, (all, href) =>
    download_file_name = internet.download href
  
  /downloaded file exists/, (all) =>
    instrument.file_exists download_file_name
)