React = require 'react'

INPUT_BORDER          =  4
INPUT_WIDTH           = 30
SYNTAX_CHAR_WIDTH     = 24
NODE_HEIGHT           = 40
SHORT_TRIANGLE_HEIGHT = 20

NodeComponent = React.createClass
  statics:
    relativeCoordsToInputNum: (type, x, y) ->
      xSoFar = 0
      inputNumSoFar = -1
      for part, i in NodeComponent.listParts(type)
        if part == 'INPUT'
          inputNumSoFar += 1
          if x >= xSoFar && y >= 0 && x < xSoFar + INPUT_WIDTH && y < NODE_HEIGHT
            return inputNumSoFar

        if part == 'INPUT'
          xSoFar += INPUT_WIDTH
        else
          xSoFar += part.length * SYNTAX_CHAR_WIDTH

      return null

    inputNumToRelativeCoords: (type, inputNum) ->
      xSoFar = 0
      inputNumSoFar = -1
      for part, i in NodeComponent.listParts(type)
        if part == 'INPUT' then inputNumSoFar += 1

        if inputNumSoFar == inputNum
          return [xSoFar + INPUT_WIDTH/2, NODE_HEIGHT/2]

        if part == 'INPUT'
          xSoFar += INPUT_WIDTH
        else
          xSoFar += part.length * SYNTAX_CHAR_WIDTH

      throw new Error("Can't find inputNum #{inputNum} in type #{type}")

    listParts: (type) ->
      if type == '+'
        ['INPUT', '+', 'INPUT']
      else if type == 'var'
        ['x']
      else if type == '.length'
        ['INPUT', '.length']
      else
        throw new Error("Don't know type #{type}")

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

    elements = []
    xSoFar = 0
    inputNumSoFar = -1
    triangleX0 = 0
    triangleX1 = 0
    for part, partNum in NodeComponent.listParts(@props.type)
      if part == 'INPUT'
        inputNumSoFar += 1

        # Remember: half of the border goes outside the width,
        #       and half of the border goes inside.
        # So x and y  have to be increased by INPUT_BORDER/2
        # and w and h have to be decreased by INPUT_BORDER
        elements.push rect
          key: partNum
          className: 'node-input'
          x: xSoFar + INPUT_BORDER/2
          y: INPUT_BORDER/2
          width: INPUT_WIDTH - INPUT_BORDER
          height: NODE_HEIGHT - INPUT_BORDER
          style: if @props.hoveringInputNum == inputNumSoFar
            stroke: 'blue'
        xSoFar += INPUT_WIDTH
      else
        width = part.length * SYNTAX_CHAR_WIDTH
        elements.push rect
          key: partNum
          className: 'node-syntax'
          x: xSoFar
          y: 0
          width: width
          height: NODE_HEIGHT
        elements.push text
          key: partNum + 0.5
          className: 'node-syntax-text'
          x: xSoFar + width / 2
          y: NODE_HEIGHT / 2
          width: width
          height: NODE_HEIGHT
          part
        triangleX0 = xSoFar
        xSoFar += width
        triangleX1 = xSoFar

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
        elements

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
