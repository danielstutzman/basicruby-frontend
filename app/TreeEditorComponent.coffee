_     = require 'underscore'
React = require 'react'

TreeEditorComponent = React.createClass
  displayName: 'TreeEditorComponent'

  getInitialState: ->
    draggingNode: null

  propTypes:
    nodesInWorkspace: React.PropTypes.array.isRequired
    dispatch:         React.PropTypes.func.isRequired

  render: ->
    { g, polygon, rect, svg, text } = React.DOM
    svg
      id: 'svg1'
      width: 400
      height: 200
      onMouseMove: (e) =>
        if draggingNode = @state.draggingNode
          @props.dispatch
            type: 'MOVE_NODE'
            nodeNum: draggingNode.nodeNum
            leftX: e.clientX - draggingNode.startX
            topY: e.clientY - draggingNode.startY
      onMouseUp: (e) =>
        @setState draggingNode: null
      rect
        x: 0.5
        y: 0.5
        width: 399
        height: 199
        fill: 'none'
        stroke: 'black'
      _.map @props.nodesInWorkspace, (node, nodeNum) =>
        do (nodeNum) =>
          g
            key: nodeNum
            className: 'draggable'
            transform: "matrix(1 0 0 1 #{node.leftX} #{node.topY})"
            onMouseDown: (e) =>
              @setState draggingNode:
                nodeNum: nodeNum
                startX: e.clientX - node.leftX
                startY: e.clientY - node.topY
            rect
              className: 'node'
              x: 0
              y: 0
            rect
              className: 'node-input'
              x: 2
              y: 2
            rect
              className: 'node-syntax'
              x: 36
              y: 2
            text
              className: 'node-syntax-text'
              x: 39
              y: 34
              node.type
            rect
              className: 'node-input'
              x: 70
              y: 2
            polygon
              points: "34,44 68,44 51,80"
              style: fill: '#fcc'

module.exports = TreeEditorComponent
