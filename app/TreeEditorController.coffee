React                 = require 'react'
TreeEditorComponent   = require './TreeEditorComponent'

class TreeEditorController
  constructor: (reactRender) ->
    @reactRender = reactRender

  setup: =>
    @render()

  render: (callback) ->
    toolsInWorkspace = []
    toolsInWorkspace.push type: '+', leftX: 30, topY: 20
    props =
      toolsInWorkspace: toolsInWorkspace
    @reactRender React.createElement(TreeEditorComponent, props), callback

module.exports = TreeEditorController
