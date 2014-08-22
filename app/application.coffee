DebuggerController = require './DebuggerController'
ExerciseController = require './ExerciseController'
ExerciseComponent  = require './ExerciseComponent'
ExerciseService    = require './ExerciseService'
SetupResizeHandler = require './setup_resize_handler'
MenuComponent      = require './MenuComponent'

$one = (selector) -> document.querySelector(selector)
$all = (selector) -> document.querySelectorAll(selector)

if window.location.hostname == 'localhost'
  window.onerror = (message, url, lineNumber) ->
    window.alert "See console: #{message} at #{url}:#{lineNumber}"

pathChanged = (path, oldPath) ->

  if path == '/'
    window.reqwest 'http://localhost:9292/api/menu.json', (props) ->
      React.renderComponent MenuComponent(props), $one('#screen')

  else if match = /^\/([0-9]+)([PYBRGO])$/.exec(path)
    service = new ExerciseService('http://localhost:9292', path)
    controller = new ExerciseController($one('#screen'), service)
    controller.setup()

  else
    window.alert "Unknown route #{path}"

document.addEventListener 'DOMContentLoaded', ->
  window.hasher.prependHash = ''
  if window.location.hash == ''
    window.hasher.setHash '/'
  window.hasher.initialized.add pathChanged
  window.hasher.changed.add pathChanged
  window.hasher.init()

  # Fix bug where Mobile Safari landscape mode scrolls too far down the page
  window.addEventListener 'orientationchange', ->
    window.scrollTo 0, 1

  window.setTimeout (-> REQUIRE['app/AstToBytecodeCompiler'].initCache()), 0
