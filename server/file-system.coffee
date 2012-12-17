# Copyright (C) 2012,13 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license
fs = require 'fs'; ensureDir = require 'ensureDir'

# instrument.file_exists name, (exists, next) -> # default next is to throw on error
fs.exists = (name, next) -> # fs.exists file_path, => next(file_exists)
  fs.stat name, (error, data) => next(not error)
  
  # look in a file for a matching regular expression. Raise an error if it is not found.
fs.contains = (name, pattern, next) ->
  fs.readFile name, 'utf8', (error, data) =>
    match = new RegExp(pattern).exec(data ? '')
    return next(false) if match.length is 0

# run a function with current working directory set - then set back afterwards
fs.in_directory = (to, action) ->
  cwd = process.cwd()
  try
    process.chdir(to)
    action()
  finally
    process.chdir(cwd)
    
# fs.mkdirs 'path/to/follow', [0x777], -> next() # make a list of directories
fs.mkdirs = (dir, mode, next) -> ensureDir(dir, mode, next)

module.exports = fs