_ = require 'underscore'
BasicRubyNew = require './BasicRubyNew'

test 'instrumentation', ->
  trace = BasicRubyNew.runRubyWithHighlighting """
    puts 3
    puts 4
    """
  _.map(trace, (line) -> [line[0], line[6]]).should.deepEqual [
    ['int', 'null'],
    ['start_call', 'puts'],
    ['call', 'puts'],

    ['int', 'null'],
    ['start_call', 'puts'],
    ['call', 'puts'],
    ['js_return', 'null']
  ]
