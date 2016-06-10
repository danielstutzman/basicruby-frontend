React = require 'react'

INPUT_BORDER =  4
INPUT_WIDTH  = 30
SYNTAX_WIDTH = 30
NODE_HEIGHT  = 40
SHORT_TRIANGLE_HEIGHT = 20

NodeComponent = React.createClass
  statics:
    relativeCoordsToInputNum: (type, x, y) ->
      if type == '+'
        if x >= 0 && y >= 0 && x < INPUT_WIDTH && y < NODE_HEIGHT then 0
        else if x >= INPUT_WIDTH + SYNTAX_WIDTH && y >= 0 &&
          x < INPUT_WIDTH + SYNTAX_WIDTH + INPUT_WIDTH && y < NODE_HEIGHT then 1
        else null
      else null
    inputNumToRelativeCoords: (type, inputNum) ->
      map =
        if type == '+'
          0: [INPUT_WIDTH/2, NODE_HEIGHT/2]
          1: [INPUT_WIDTH + SYNTAX_WIDTH + INPUT_WIDTH/2, NODE_HEIGHT/2]
        else if type == 'var'
          {}
        else
          throw new Error("Don't know type #{type}")
      if map[inputNum] == undefined
        throw new Error("Can't find key #{inputNum} in map #{JSON.stringify(map)}")
      map[inputNum]

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

    parts = []
    nextX = 0
    if @props.type == '+'
      # Remember: half of the border goes outside the width,
      #       and half of the border goes inside.
      # So x and y  have to be increased by INPUT_BORDER/2
      # and w and h have to be decreased by INPUT_BORDER
      parts.push rect
        key: 1
        className: 'node-input'
        x: nextX + INPUT_BORDER/2
        y: INPUT_BORDER/2
        width: INPUT_WIDTH - INPUT_BORDER
        height: NODE_HEIGHT - INPUT_BORDER
        style: if @props.hoveringInputNum == 0
          stroke: 'blue'
      nextX += INPUT_WIDTH

      parts.push rect
        key: 2
        className: 'node-syntax'
        x: nextX
        y: 0
        width: SYNTAX_WIDTH
        height: NODE_HEIGHT
      parts.push text
        key: 3
        className: 'node-syntax-text'
        x: nextX + SYNTAX_WIDTH / 2
        y: NODE_HEIGHT / 2
        width: SYNTAX_WIDTH
        height: NODE_HEIGHT
        @props.type
      nextX += SYNTAX_WIDTH

      parts.push rect
        key: 4
        className: 'node-input'
        x: nextX + INPUT_BORDER/2
        y: INPUT_BORDER/2
        width: INPUT_WIDTH - INPUT_BORDER
        height: NODE_HEIGHT - INPUT_BORDER
        style: if @props.hoveringInputNum == 1
          stroke: 'blue'
      nextX += INPUT_WIDTH

      triangleX0 = INPUT_WIDTH
      triangleX1 = INPUT_WIDTH + SYNTAX_WIDTH
    else if @props.type == 'var'
      parts.push rect
        key: 2
        className: 'node-syntax'
        x: nextX
        y: 0
        width: SYNTAX_WIDTH
        height: NODE_HEIGHT
      parts.push text
        key: 3
        className: 'node-syntax-text'
        x: nextX + SYNTAX_WIDTH / 2
        y: NODE_HEIGHT / 2
        width: SYNTAX_WIDTH
        height: NODE_HEIGHT
        'x'
      nextX += SYNTAX_WIDTH

      triangleX0 = 0
      triangleX1 = SYNTAX_WIDTH

    tipX = @props.overrideTipX || (@props.leftX + (triangleX0 + triangleX1)/2)
    tipY = @props.overrideTipY || (@props.topY + NODE_HEIGHT + SHORT_TRIANGLE_HEIGHT)

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
        parts

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
        points: "#{@props.leftX + triangleX0},#{@props.topY + NODE_HEIGHT} " +
          "#{@props.leftX + triangleX1},#{@props.topY + NODE_HEIGHT} " +
          "#{tipX},#{tipY}"
        style: fill: '#fcc'

module.exports = NodeComponent
