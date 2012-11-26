# Copyright (C) 2012,13 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license
module.exports = (request, response) -> require('script-runner').fork 'gwt', request, response
