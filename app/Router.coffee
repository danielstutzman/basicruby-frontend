ApiService          = require './ApiService'
DebuggerController  = require './DebuggerController'
ExerciseController  = require './ExerciseController'
ExerciseComponent   = require './ExerciseComponent'
MenuComponent       = require './MenuComponent'
NotFoundComponent   = require './NotFoundComponent'
Router              = require './Router'

class Router

  constructor: (service) ->
    @service = service

  render: (path, reactRender) ->
    if path == '/'
      @service.getMenu (data) ->
        reactRender MenuComponent(data), null

    else if match = /^\/([0-9]+)([PYBRGO])(\/([0-9]+))?$/.exec(path)
      controller = new ExerciseController(@service, reactRender, path)
      controller.setup()

    else if path == '/test.html'
      # do nothing

    else
      console.error 'path', path
      reactRender NotFoundComponent({}), null

module.exports = Router
