_     = require 'underscore'
React = require 'react'

TreeEditorComponent = React.createClass
  displayName: 'TreeEditorComponent'

  propTypes:
    toolsInWorkspace: React.PropTypes.array.isRequired

  render: ->
    { g, polygon, rect, svg, text } = React.DOM
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
      _.map @props.toolsInWorkspace, (tool, i) ->
        g
          key: i
          className: 'draggable'
          transform: "matrix(1 0 0 1 #{tool.leftX} #{tool.topY})"
          rect
            className: 'tool'
            x: 0
            y: 0
          rect
            className: 'tool-input'
            x: 2
            y: 2
          rect
            className: 'tool-syntax'
            x: 36
            y: 2
          text
            className: 'tool-syntax-text'
            x: 39
            y: 34
            '+'
          rect
            className: 'tool-input'
            x: 70
            y: 2
          polygon
            points: "34,44 68,44 51,80"
            style: fill: '#fcc'

module.exports = TreeEditorComponent
