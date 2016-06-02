BasicRubyNew = require './BasicRubyNew'
fs           = require 'fs'
path         = require 'path'
yaml         = require 'js-yaml'

yamlPath = path.resolve __dirname, 'instrument_tests.yaml'
doc = yaml.safeLoad fs.readFileSync(yamlPath, 'utf8')
for testCaseName, testCase of doc
  test testCaseName, ->
    trace = BasicRubyNew.runRubyWithHighlighting testCase.code
    nodeNames = (line[0] for line in trace)
    nodeNames.should.deepEqual testCase.trace
