React = require 'react'

TreeEditorComponent = React.createClass
  displayName: 'TreeEditorComponent'
  render: ->
    { rect, svg } = React.DOM
    svg
      id: 'svg1'
      width: 400
      height: 200
      rect
        x: 0.5
        y: 0.5
        width: 399
        height: 199
        fill: 'none'
        stroke: 'black'

module.exports = TreeEditorComponent
