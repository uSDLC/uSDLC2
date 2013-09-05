# Copyright (C) 2013 paul@marrington.net, see GPL for license
files = require 'files', path = require 'path'
dirs = require 'dirs'

module.exports =
  copy: (from..., to) -> @async ->
    files.is_dir to, (error, is_dir) ->
      return @fail(error) if error
      if is_dir
        do copy_one = ->
          return @pass() if not from.length
          name = path.basename(from)
          files.copy from, "#{to}/#{name}", (error) ->
            return @fail(error) if error
            copy_one()
      else
        return @fail("One from for #{to}") if from.length
        files.copy from, to, (error) ->
          @check_for_error(error)
        
  rmdirs: (dir) -> @async ->
    dirs.rmdirs dir, (error) -> @check_for_error(error)