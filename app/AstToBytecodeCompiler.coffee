Opal = require 'opal'
require 'basicruby-interpreter'

dump = (sexp, level) ->
  out = ''
  for i in [0..level]
    out += '  '
  out += sexp.array[0]
  for child in sexp.array
    if typeof child == 'string'
      out += ' ' + child
  console.log out
  for child in sexp.array
    if child.array
      dump child, level + 1

cache = {}
initCache = ->
  return if cache.parser # only one initCache is needed
  parser = Opal.Opal._scope.Parser.$new()
  sexpRuntime = parser.$parse Opal.BytecodeInterpreter.$RUNTIME_PRELUDE()
  compiler = Opal.AstToBytecodeCompiler.$new Opal.top
  bytecodesRuntime = compiler.$compile_program 'Runtime', sexpRuntime
  bytecodesRuntime = _.reject bytecodesRuntime, (bytecode) ->
    bytecode[0] == 'token'
  _.each bytecodesRuntime, (bytecode) ->
    _.each bytecode, (part) ->
      type = typeof(part)
      if type != 'string' && type != 'number' && type != 'boolean'
        console.error bytecode
        throw "Bytecode should return only
          arrays of strings, numbers, and booleans, not #{bytecode.$inspect()}"
  cache = { parser, compiler, bytecodesRuntime }

compile = (pairs) ->
  throw 'Call initCache() first' if !cache.parser
  newCompiler = Opal.AstToBytecodeCompiler.$new Opal.top
  bytecodes = []
  bytecodes = bytecodes.concat cache.bytecodesRuntime, [['discard']]
  for pair in pairs
    [sectionName, code] = pair
    sexp = cache.parser.$parse code
    #dump sexp, 0
    bytecodesNew = newCompiler.$compile_program sectionName, sexp
    #for bytecode in bytecodesNew
    #  console.log bytecode.join(' ')
    bytecodes = bytecodes.concat bytecodesNew, [['discard']]
  bytecodes

module.exports =
  initCache: initCache
  compile: compile
