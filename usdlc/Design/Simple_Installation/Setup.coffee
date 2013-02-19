gwt = global.gwt # set by uSDLC2/scripts/gwt

# Module requirements
internet = require('Internet')()
Processes = require('processes')
path = require('path')
os = require('operating-system')
fs = require('file-system')

# Common variable across instrumentation
file_name = ''
temp_directory = ''
file_path = -> path.join temp_directory, file_name
gwt.rules( # Rules used by child pages
  /(\w+) operating system/,
    (all, system) => gwt.skip.section if not os.expecting(system)

  /Internet access/,
    =>
      gwt.pause()
      internet.available (error) =>
        gwt.skip.section() if error
        gwt.resume()

  /working with a file called '(.*)'/,
    (all, name) => file_name = name

  /in a temporary directory ending in '(.*)'/,
    (all, ending) =>
      temp_directory = path.join os.tmpDir(), ending
      gwt.pause()
      fs.mkdir temp_directory, =>
        gwt.resume()

  /download from github project '(.*)' at '(.*)'/,
    (all, project, at) =>
      gwt.pause()
      internet.download.to(file_path()).
        from "https://raw.github.com/#{project}/#{at}/#{file_name}", =>
          gwt.resume()

  /file exists/,
    =>
      gwt.pause()
      fp = file_path()
      (all) => fs.exists fp, (exists) =>
        throw "#{fp} expected, but does not exist" if not exists
          gwt.resume()

  /run '(.*)'/,
    (all, command_line) =>
      gwt.pause()
      fs.in_directory temp_directory, =>
        [program, args...] = command_line.split ' '
        Processes().spawn program, args, =>
          gwt.resume()

  /if the file does not exist/,
    =>
      gwt.pause()
      fs.exists file_path(), (exists) =>
        gwt.skip.statements() if exists
        gwt.resume()

  /and confirm a file '(.*)' now exists/,
    (all, name) =>
      gwt.pause()
      fs.exists path.join(temp_directory, name), (exists) =>
        throw "#{name} expected to exist" if not exists
        gwt.resume()

  /download from github project '(.*)'/,
    (all, project) =>
      gwt.pause()
      projectName = project.split('/').pop()
      temp_directory = path.join os.tmpDir(), projectName
      fs.mkdir temp_directory, =>
        old_file_name = file_name
        file_name = 'install-usdlc-on-unix.sh'
        at = 'master/release'
        internet.download.to(file_path()).
        from "https://raw.github.com/#{project}/#{at}/#{file_name}", =>
          instrument.in_directory temp_directory, =>
            Processes().spawn '/bin/bash', [file_path(), '.', 'no-go'], =>
              file_name = old_file_name
              gwt.resume()
)
