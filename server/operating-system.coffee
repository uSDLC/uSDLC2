# Copyright (C) 2012,13 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license
os = require 'os'

# some scripts are platform dependent - so provide a check
os.expecting = (system) -> # os.expecting('windows|unix|darwin|linux')
  runningOn = os.type().toLowerCase()
  system = system.toLowerCase()
  return system is runningOn or system is 'unix' and runningOn isnt 'windows'

module.exports = os