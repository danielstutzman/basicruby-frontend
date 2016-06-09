React = require 'react'

INPUT_WIDTH  = 30
INPUT_HEIGHT = 40

NodeComponent = React.createClass
  statics:
    relativeCoordsToInputNum: (x, y) ->
      if x >= 0 && y >= 0 && x < INPUT_WIDTH && y < INPUT_HEIGHT
        0
      else if x >= 70 && y >= 0 && x < 70 + INPUT_WIDTH && y < INPUT_HEIGHT
        1
      else
        null
    inputNumToRelativeCoords: (inputNum) ->
      if inputNum == 0
        [10, 10]
      else
        [95, 10]

  displayName: 'NodeComponent'

  getInitialState: ->
    draggingNode: null
    draggingTip: null

  propTypes:
    leftX:             React.PropTypes.number.isRequired
    topY:              React.PropTypes.number.isRequired
    overrideTipX:      React.PropTypes.number
    overrideTipY:      React.PropTypes.number
    type:              React.PropTypes.string.isRequired
    hoveringInputNum:  React.PropTypes.number
    startDraggingNode: React.PropTypes.func.isRequired
    startDraggingTip:  React.PropTypes.func.isRequired

  shouldComponentUpdate: (nextProps, nextState) ->
    shouldUpdate =
      nextProps.leftX            != @props.leftX or
      nextProps.topY             != @props.topY or
      nextProps.overrideTipX     != @props.overrideTipX or
      nextProps.overrideTipY     != @props.overrideTipY or
      nextProps.type             != @props.type or
      nextProps.hoveringInputNum != @props.hoveringInputNum or
      nextState.draggingNode     != @state.draggingNode or # object comparison
      nextState.draggingTip      != @state.draggingTip     # object comparison

  render: ->
    { g, polygon, rect, svg, text } = React.DOM

    tipX = @props.overrideTipX || @props.leftX + 50
    tipY = @props.overrideTipY || @props.topY + 70

    g {},
      g
        className: 'draggable'
        transform: "matrix(1 0 0 1 #{@props.leftX} #{@props.topY})"
        onMouseDown: (e) =>
          e.preventDefault()
          @props.startDraggingNode
            startX: e.clientX - @props.leftX
            startY: e.clientY - @props.topY
            x: @props.leftX
            y: @props.topY
        rect
          className: 'node'
          x: 0
          y: 0
        rect
          className: 'node-input'
          x: 2
          y: 2
          width: INPUT_WIDTH
          height: INPUT_HEIGHT
          style: if @props.hoveringInputNum == 0
            stroke: 'blue'
        rect
          className: 'node-syntax'
          x: 36
          y: 2
        text
          className: 'node-syntax-text'
          x: 39
          y: 34
          @props.type
        rect
          className: 'node-input'
          x: 70
          y: 2
          width: INPUT_WIDTH
          height: INPUT_HEIGHT
          style: if @props.hoveringInputNum == 1
            stroke: 'blue'

      rect
        className: 'tip-handle draggable'
        x: tipX - 10
        y: tipY - 10
        width: 20
        height: 20
        fill: 'white'
        onMouseDown: (e) =>
          e.preventDefault()
          @props.startDraggingTip
            x: e.clientX
            y: e.clientY
      polygon
        points: "#{@props.leftX + 34},#{@props.topY + 44} " +
          "#{@props.leftX + 68},#{@props.topY + 44} #{tipX},#{tipY}"
        style: fill: '#fcc'

module.exports = NodeComponent
