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

rpc = new easyXDM.Rpc({ remote: 'http://localhost:9292/easyxdm.html' },
  { remote: { request: {} } })

pathChanged = (path, oldPath) ->

  if path == '/'
    rpc.request method: 'GET', url: '/api/menu.json', (result) ->
      data = JSON.parse(result.data)
      React.renderComponent MenuComponent(data), $one('#screen')

  else if match = /^\/([0-9]+)([PYBRGO])(\/([0-9]+))?$/.exec(path)
    service = new ExerciseService(rpc, path)
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
