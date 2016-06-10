_             = require 'underscore'
NodeComponent = require './NodeComponent'
React         = require 'react'

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
        e.preventDefault()
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
        e.preventDefault()
        if node = @state.draggingNode
          @props.dispatch
            type: 'MOVE_NODE'
            nodeNum: node.nodeNum
            leftX: e.clientX - node.startX
            topY: e.clientY - node.startY
          @setState draggingNode: null
        else if tip = @state.draggingTip
          for node, nodeNum in @props.nodesInWorkspace
            hoveringInputNum = NodeComponent.relativeCoordsToInputNum(
              node.type, e.clientX - node.leftX, e.clientY - node.topY)
            if hoveringInputNum isnt null
              @props.dispatch
                type: 'MOVE_TARGET'
                nodeNum: tip.nodeNum
                target:
                  nodeNum: nodeNum
                  inputNum: hoveringInputNum
          @setState draggingTip: null
      rect
        x: 0.5
        y: 0.5
        width: 399
        height: 199
        fill: 'none'
        stroke: 'black'
      _.map @props.nodesInWorkspace, (node, nodeNum) =>
        do (node, nodeNum) =>
          [leftX, topY] =
            if @state.draggingNode?.nodeNum == nodeNum
              [@state.draggingNode.x, @state.draggingNode.y]
            else
              [node.leftX, node.topY]

          [overrideTipX, overrideTipY] =
            if @state.draggingTip?.nodeNum == nodeNum
              [@state.draggingTip.x, @state.draggingTip.y]
            else if node.target
              targetNode = @props.nodesInWorkspace[node.target.nodeNum]
              [relativeX, relativeY] = NodeComponent.inputNumToRelativeCoords(
                targetNode.type, node.target.inputNum)
              [relativeX + targetNode.leftX, relativeY + targetNode.topY]
            else
              [null, null]

          draggingTip = @state.draggingTip
          hoveringInputNum =
            if draggingTip && nodeNum != draggingTip.nodeNum # can't point to itself
              NodeComponent.relativeCoordsToInputNum(
                node.type, draggingTip.x - node.leftX, draggingTip.y - node.topY)
            else
              null

          React.createElement NodeComponent,
            key: nodeNum
            leftX: leftX
            topY: topY
            overrideTipX: overrideTipX
            overrideTipY: overrideTipY
            type: node.type
            hoveringInputNum: hoveringInputNum
            startDraggingNode: (params) =>
              params.nodeNum = nodeNum
              @setState draggingNode: params
            startDraggingTip: (params) =>
              params.nodeNum = nodeNum
              @setState draggingTip: params

module.exports = TreeEditorComponent
