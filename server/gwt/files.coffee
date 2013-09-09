# Copyright (C) 2013 paul@marrington.net, see GPL for license
files = require 'files', path = require 'path'
dirs = require 'dirs'; fs = require 'fs'

module.exports =
  copy: (from..., to) -> @queue ->
    files.is_dir to, (error, is_dir) =>
      if is_dir
        do copy_one = =>
          return @pass() if not from.length
          target = from.shift()
          name = path.basename(target)
          files.copy target, "#{to}/#{name}", (error) =>
            return @fail(error) if error
            copy_one()
      else
        if from.length > 1
          return @fail("usage: copy(from_file, to_file)")
        files.copy from[0], to, (error) =>
          @check_for_error(error)
        
  mkdirs: (dir) -> @queue ->
    dirs.mkdirs dir, (error) => @check_for_error(error)
    
  rmdirs: (dir) -> @queue ->
    dirs.rmdirs dir, (error) => @check_for_error(error)
    
  rename: (old_path, new_path) -> @queue ->
    fs.rename old_path, new_path, (error) =>
      @check_for_error(error)
