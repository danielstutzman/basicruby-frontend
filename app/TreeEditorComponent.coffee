_     = require 'underscore'
React = require 'react'

TreeEditorComponent = React.createClass
  displayName: 'TreeEditorComponent'

  getInitialState: ->
    draggingNode: null
    draggingTip: null

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
        if node = @state.draggingNode
          @setState draggingNode:
            nodeNum: node.nodeNum
            x: e.clientX - node.startX
            y: e.clientY - node.startY
            startX: node.startX
            startY: node.startY
        else if tip = @state.draggingTip
          @setState draggingTip:
            nodeNum: tip.nodeNum
            x: e.clientX
            y: e.clientY
      onMouseUp: (e) =>
        if node = @state.draggingNode
          @props.dispatch
            type: 'MOVE_NODE'
            nodeNum: node.nodeNum
            leftX: e.clientX - node.startX
            topY: e.clientY - node.startY
          @setState draggingNode: null
        else if tip = @state.draggingTip
          targetNodeNum = null
          for node, nodeNum in @props.nodesInWorkspace
            if nodeNum != tip.nodeNum && # node can't point to itself
               e.clientX >= node.leftX &&
               e.clientY >= node.topY &&
               e.clientX < node.leftX + 140 &&
               e.clientY < node.topY + 200
              targetNodeNum = nodeNum
          if targetNodeNum
            @props.dispatch
              type: 'MOVE_TIP'
              nodeNum: tip.nodeNum
              tipNodeNum: targetNodeNum
          @setState draggingTip: null
      rect
        x: 0.5
        y: 0.5
        width: 399
        height: 199
        fill: 'none'
        stroke: 'black'
      _.map @props.nodesInWorkspace, (node, nodeNum) =>
        do (nodeNum) =>
          if @state.draggingNode?.nodeNum == nodeNum
            leftX = @state.draggingNode.x
            topY  = @state.draggingNode.y
          else
            leftX = node.leftX
            topY  = node.topY
          g
            key: nodeNum
            g
              className: 'draggable'
              transform: "matrix(1 0 0 1 #{leftX} #{topY})"
              onMouseDown: (e) =>
                @setState draggingNode:
                  nodeNum: nodeNum
                  startX: e.clientX - node.leftX
                  startY: e.clientY - node.topY
                  x: node.leftX
                  y: node.topY
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

            if @state.draggingTip?.nodeNum == nodeNum
              tipX = @state.draggingTip.x
              tipY = @state.draggingTip.y
            else if node.tipNodeNum
              targetNode = @props.nodesInWorkspace[node.tipNodeNum]
              tipX = targetNode.leftX + 10
              tipY = targetNode.topY + 10
            else
              tipX = node.leftX + 50
              tipY = node.topY + 70
            rect
              className: 'tip-handle draggable'
              x: tipX - 10
              y: tipY - 10
              width: 20
              height: 20
              fill: 'white'
              onMouseDown: (e) =>
                @setState draggingTip:
                  nodeNum: nodeNum
                  x: e.clientX
                  y: e.clientY
            polygon
              points: "#{node.leftX + 34},#{node.topY + 44} " +
                "#{node.leftX + 68},#{node.topY + 44} #{tipX},#{tipY}"
              style: fill: '#fcc'

module.exports = TreeEditorComponent
