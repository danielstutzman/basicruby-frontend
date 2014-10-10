ApiService             = require './ApiService'
DebuggerController     = require './DebuggerController'
ExerciseController     = require './ExerciseController'
ExerciseComponent      = require './ExerciseComponent'
MenuComponent          = require './MenuComponent'
TutorController        = require './TutorController'
TutorMenuComponent     = require './TutorMenuComponent'

$one = (selector) -> document.querySelector(selector)
$all = (selector) -> document.querySelectorAll(selector)

if window.location.hostname == 'localhost'
  window.onerror = (message, url, lineNumber) ->
    window.alert "See console: #{message} at #{url}:#{lineNumber}"

if window.location.hostname == 'localhost'
  apiHost = 'localhost:9292'
else
  apiHost = 'basicruby.danstutzman.com'
service = new ApiService(apiHost)

pathChanged = (path) ->

  if path == '/'
    service.getMenu (data) ->
      React.renderComponent MenuComponent(data), $one('#screen')

  else if path == '/tutor'
    service.getTutorMenu (data) ->
      React.renderComponent TutorMenuComponent(data), $one('#screen')

  else if match = /^\/tutor\/exercise\/([CD][0-9]+)$/.exec(path)
    taskId = match[1]
    controller = new TutorController(service, taskId)
    controller.setup()

  else if match = /^\/([0-9]+)([PYBRGO])(\/([0-9]+))?$/.exec(path)
    controller = new ExerciseController($one('#screen'), service, path)
    controller.setup()

  else
    window.alert "Unknown route #{path}"

document.addEventListener 'DOMContentLoaded', ->
  window.History.Adapter.bind window, 'statechange', ->
    pathChanged History.getState().hash
  unless window.location.hash
    pathChanged window.location.pathname
  window.History.onClick = (e) ->
    e.preventDefault() # don't re-request page by following clicked <a> link
    # Use currentTarget instead of target for when there's an a tag around a div
    href = e.currentTarget.getAttribute('href')
    History.pushState null, null, href

  # Fix bug where Mobile Safari landscape mode scrolls too far down the page
  window.addEventListener 'orientationchange', ->
    window.scrollTo 0, 1

  window.setTimeout (-> REQUIRE['app/AstToBytecodeCompiler'].initCache()), 0
