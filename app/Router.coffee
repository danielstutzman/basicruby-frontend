ApiService          = require './ApiService'
DebuggerController  = require './DebuggerController'
ExerciseController  = require './ExerciseController'
ExerciseComponent   = require './ExerciseComponent'
MenuComponent       = require './MenuComponent'
Router              = require './Router'
TutorController     = require './TutorController'
TutorMenuComponent  = require './TutorMenuComponent'

class Router

  constructor: (service) ->
    @service = service

  render: (path, reactRender) ->
    if path == '/'
      @service.getMenu (data) ->
        reactRender MenuComponent(data), null

    else if path == '/tutor'
      @service.getTutorMenu (data) ->
        reactRender TutorMenuComponent(data), null

    else if match = /^\/tutor\/exercise\/([CD][0-9]+)$/.exec(path)
      taskId = match[1]
      controller = new TutorController(@service, reactRender, taskId)
      controller.setup()

    else if match = /^\/([0-9]+)([PYBRGO])(\/([0-9]+))?$/.exec(path)
      controller = new ExerciseController(@service, reactRender, path)
      controller.setup()

    else if path == '/test.html'
      # do nothing

    else
      throw "Unknown route #{path}"

module.exports = Router
