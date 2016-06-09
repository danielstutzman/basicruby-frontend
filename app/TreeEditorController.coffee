React                 = require 'react'
TreeEditorComponent   = require './TreeEditorComponent'

class TreeEditorController
  constructor: (reactRender, store) ->
    @reactRender = reactRender
    @store       = store

  setup: =>
    @render()

  render: (callback) ->
    props =
      nodesInWorkspace: @store.getState().nodesInWorkspace
      dispatch: (action) =>
        @store.dispatch action
        @render callback
    @reactRender React.createElement(TreeEditorComponent, props), callback

module.exports = TreeEditorController
