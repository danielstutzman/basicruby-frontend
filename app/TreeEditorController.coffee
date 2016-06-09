React                 = require 'react'
TreeEditorComponent   = require './TreeEditorComponent'

class TreeEditorController
  constructor: (reactRender) ->
    @reactRender = reactRender

  setup: =>
    @render()

  render: (callback) ->
    props = {}
    @reactRender React.createElement(TreeEditorComponent, props), callback

module.exports = TreeEditorController
