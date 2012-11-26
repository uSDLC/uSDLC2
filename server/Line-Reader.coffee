# Copyright (C) 2012,13 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license

# Read lines from a stream - with the same stream pattern of pause and resume.
class Line_Reader extends require('stream').Stream
  constructor: (@reader) ->
    @paused = false
    @lines = []
    buffer = ''
    @reader.setEncoding 'utf8'
    
    @reader.on 'data', (data) =>
      @lines = @lines.concat (buffer + data).split(/\r?\n/)
      buffer = @lines.pop()
      @emitLines()
      
    @reader.on 'end', =>
      @emit('data', buffer) if buffer.length
      @emit('end')
      
    @reader.on 'close', => @emit 'close'
    
  pause: -> @paused = true; @reader.pause();
  resume: -> @paused = false; @emitLines(); @reader.resume()
  destroy: -> @reader.destroy()
  emitLines: -> @emit('data', @lines.shift()) while @lines.length and not @paused
    
module.exports = (reader) -> new Line_Reader(reader)