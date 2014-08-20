DebuggerController = require './DebuggerController'
ExerciseController = require './ExerciseController'
ExerciseComponent  = require './ExerciseComponent'
SetupResizeHandler = require('./setup_resize_handler')

$one = (selector) -> document.querySelector(selector)
$all = (selector) -> document.querySelectorAll(selector)

if window.location.hostname == 'localhost'
  window.onerror = (message, url, lineNumber) ->
    window.alert "See console: #{message} at #{url}:#{lineNumber}"

document.addEventListener 'DOMContentLoaded', ->
  if $one('body.exercise') && !$one('div.exercise.purple')
    reqwest 'http://localhost:9292/api/exercise/1Y.json', (model) ->
      controller = new ExerciseController($one('div.exercise'), model)
      controller.setup()

  # Fix bug where Mobile Safari landscape mode scrolls too far down the page
  window.addEventListener 'orientationchange', ->
    window.scrollTo 0, 1
