ApiService           = require './ApiService'
ExerciseController   = require './ExerciseController'
ExerciseComponent    = require './ExerciseComponent'
MenuComponent        = require './MenuComponent'
NotFoundComponent    = require './NotFoundComponent'
TreeEditorController = require './TreeEditorController'
Router               = require './Router'

class Router

  constructor: (service, store) ->
    @service = service
    @store   = store

  render: (path, reactRender) ->
    if path == '/'
      @service.getMenu (data) ->
        reactRender React.createElement(MenuComponent, data), null

    else if path == '/tree.html'
      controller = new TreeEditorController(reactRender, @store)
      controller.setup()

    else if match = /^\/([0-9]+)([PYBRGO])(\/([0-9]+))?$/.exec(path)
      controller = new ExerciseController(@service, reactRender, path)
      controller.setup()

    else if path == '/test.html'
      # do nothing

    else
      console.error 'path', path
      reactRender React.createElement(NotFoundComponent, {}), null

module.exports = Router
