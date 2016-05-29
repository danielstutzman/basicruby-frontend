_                  = require 'underscore'
React              = require 'react'
CasesComponent     = require './CasesComponent'
SetupResizeHandler = require './setup_resize_handler'
classNames         = require 'classnames'

type          = React.PropTypes
RELOAD_ICON   = "\u27f3"
RIGHT_ARROW   = "\u279c"
EM_DASH       = "\u2014"
X_FOR_CLOSE   = "\u00d7"
EM_DASH       = "\u2014"
NEWLINE_ARROW = "\u21a9"
NBSP          = "\u00a0"

ExerciseComponent = React.createClass

  displayName: 'ExerciseComponent'

  propTypes:
    color:        type.string.isRequired
    initialCode:  type.string.isRequired
    cases:        type.array.isRequired
    popup:        type.string
    topicTitle:   type.string
    youtubeId:    type.string
    videoScript:  type.string
    doCommand:    type.object.isRequired
    traceContents:type.array.isRequired

  getInitialState: ->
    codeMirror: null
    retrieveNewCode: (->) # since it's a required property
    initialCode: @props.initialCode
    hoverRow: null
    hoverCol: null

  componentDidMount: ->
    # setup CodeMirror
    options =
      mode: 'ruby'
      lineNumbers: true
      autofocus: true
      readOnly: false
      lineWrapping: true
    textarea = @refs.code.getDOMNode()
    isMobileSafari = ->
       navigator.userAgent.match(/(iPod|iPhone|iPad)/) &&
       navigator.userAgent.match(/AppleWebKit/)
    codeMirrors = []
    if isMobileSafari()
      @setState codeMirror: null, retrieveNewCode: (-> textarea.value)
    else
      codeMirror = CodeMirror.fromTextArea textarea, options
      codeMirror.on 'focus', => @props.doCommand.closePopup()
      codeMirrors.push codeMirror
      makeRetriever = (codeMirror) -> (-> codeMirror.getValue())
      @setState
        codeMirror: codeMirror
        retrieveNewCode: makeRetriever(codeMirror)

    if @cases && @cases[0] && @cases[0].code
      for textareaTests in @$div.querySelectorAll('textarea.expected')
        options =
          mode: 'ruby'
          lineNumbers: true
          readOnly: 'nocursor'
          lineWrapping: true
        codeMirror = CodeMirror.fromTextArea textareaTests, options
        codeMirror.on 'focus', => @props.doCommand.closePopup()
        codeMirrors.push codeMirror

    # TODO: destroy old resize handler before setting up a new one
    #SetupResizeHandler.setupResizeHandler codeMirrors

  componentDidUpdate: (prevProps, prevState) ->
    if @state.codeMirror
      if @props.initialCode != prevProps.initialCode
        @refs.code.getDOMNode().value = @props.initialCode
        @state.codeMirror.setValue @props.initialCode
        @setState initialCode: @props.initialCode
      if @props.color != prevProps.color
        @state.codeMirror.refresh() # in case it appeared (from purple)

  _renderExpr: (expr) ->
    { td, span } = React.DOM
    exprTypeString = expr.$class().$to_s()
    span { className: 'value' },
      span { className: 'type' }, exprTypeString
      if exprTypeString == 'Number'
        span { className: 'number' }, expr
      else if exprTypeString == 'String' && expr.length > 0
        span { className: 'string' },
          _.map [0...expr.length], (i) ->
            span { key: i, className: 'char' },
              expr.charAt(i).replace("\n", NEWLINE_ARROW).replace(" ", NBSP)
      else
        span { className: 'empty' }

  render: ->
    { a, br, button, code, div, h1, iframe, input, label, p, span, table, td,
      textarea, th, tr } = React.DOM

    hasScript = (@props.videoScript && !@props.youtubeId) && 'has-video-script'
    hasVideo  = @props.youtubeId && 'has-video'
    class_ = ['ExerciseComponent', @props.color, hasVideo, hasScript].join(' ')
    div { className: class_ },
      div { className: 'title' },
        a { className: 'logo-link', href: '/', onClick: window.history.onClick }
        EM_DASH
        "#{@props.topicNum}. #{@props.topicTitle}"

      div { className: 'buttons-above' },
        if @props.color == 'yellow' || @props.color == 'blue'
          button
            className: 'do-another'
            disabled: @props.doCommand.nextRep == null ||
                      @props.cases[0].actual_output == undefined
            onClick: (e) => @props.doCommand.nextRep e, true
            onFocus: => @props.doCommand.closePopup()
            "#{RELOAD_ICON} See another"

        if @props.color == 'yellow' || @props.color == 'blue' ||
           @props.youtubeId
          button
            className: 'next'
            disabled: @props.doCommand.next == null ||
              (@props.cases[0].actual_output == undefined && !@props.youtubeId)
            onClick: (e) => @props.doCommand.next e
            onFocus: => @props.doCommand.closePopup()
            "#{RIGHT_ARROW} Go on"

        if @props.color == 'red' || @props.color == 'green'
          button
            className: 'show-solution'
            disabled: true
            onClick: => @props.doCommand.showSolution()
            onFocus: => @props.doCommand.closePopup()
            'Show solution'

      switch @props.color
        when 'purple'
          div { className: 'banner purple' }, 'Watch the introduction'
        when 'yellow'
          div { className: 'banner yellow' }, 'Run this example'
        when 'blue'
          div
            className: 'banner blue'
            'Predict the output'
        when 'red'
          div
            className: 'banner red'
            'Fix this program so tests pass'
        when 'green'
          div
            className: 'banner green'
            'Write new code so tests pass'
        when 'orange'
          div { className: 'banner green' }, 'Simplification'

      if @props.youtubeId
        iframe
          width: 840
          height: 480
          frameBorder: 0
          allowFullScreen: true
          src: "//www.youtube.com/embed/#{@props.youtubeId}?rel=0&autoplay=0"

      div { className: 'col-1-of-2' },
        div { className: 'wrapper' },
          div { className: 'code-header' },
            div { className: 'indent' }
              label { className: 'code' },
                switch @props.color
                  when 'purple' then 'Code to look over'
                  when 'yellow' then 'Code to look over'
                  when 'blue'   then 'Code to look over'
                  when 'red'    then 'Code to edit'
                  when 'green'  then 'Write code here'
                  when 'orange' then 'Code to simplify'
          div { className: 'code-wrapper' },
            div { className: 'code-wrapper2' },
              div { className: 'code-wrapper3' },
                textarea
                  ref: 'code'
                  className: 'code'
                  defaultValue: @props.initialCode
                  onFocus: => @props.doCommand.closePopup()
          div { style: { height: '50%', overflow: 'scroll' } },
            table { className: 'trace' },
              if @props.traceContents.length > 0
                tr {},
                  th {}, 'Line'
                  th { className: 'description' }, 'Description'
                  th {}, 'Value'
                  th {}, 'Output'
              _.map @props.traceContents, (line, i) =>
                do (i) =>
                  [indentation, lineNum, text, replaceCallback, replaceResultCallback,
                    clearCallback, expr, output] = line
                  tr { key: i, className: 'line' },
                    td
                      className: classNames
                        'line-num': true
                        hover: @state.hoverRow == i and @state.hoverCol == 'highlight'
                      onMouseOver: =>
                        replaceCallback @state.codeMirror
                        @setState hoverRow: i, hoverCol: 'highlight'
                      onMouseOut: =>
                        clearCallback @state.codeMirror
                        @setState hoverRow: null, hoverCol: null
                      Array(indentation + 1).join("\u00a0\u00a0") + lineNum
                    td
                      className: classNames
                        description: true
                        hover: @state.hoverRow == i and @state.hoverCol == 'highlight'
                      onMouseOver: =>
                        replaceCallback @state.codeMirror
                        @setState hoverRow: i, hoverCol: 'highlight'
                      onMouseOut: =>
                        clearCallback @state.codeMirror
                        @setState hoverRow: null, hoverCol: null
                      dangerouslySetInnerHTML: __html:
                        Array(indentation + 1).join("\u00a0\u00a0") + text
                    if expr != null
                      td
                        className: classNames
                          hover: @state.hoverRow == i and @state.hoverCol == 'value'
                        onMouseOver: =>
                          replaceResultCallback @state.codeMirror
                          @setState hoverRow: i, hoverCol: 'value'
                        onMouseOut: =>
                          clearCallback @state.codeMirror
                          @setState hoverRow: null, hoverCol: null
                        @_renderExpr expr
                    else
                      td {}
                    td { className: 'output' },
                      if output
                        _.map [0...output.length], (i) ->
                          span { key: i, className: 'char' },
                            output.charAt(i).replace("\n", NEWLINE_ARROW).replace(
                              " ", NBSP)

        div { className: 'margin' } # because %-based margins don't work

      CasesComponent _.extend(@props, retrieveNewCode: @state.retrieveNewCode)

      br { style: { clear: 'both' } }

      div { className: 'video-script' },
        @props.videoScript

      if @props.popup == 'PASSED'
        div
          className: 'popup passed'
          a
            className: 'close-button'
            href: '#'
            onClick: (e) =>
              @props.doCommand.closePopup()
              e.preventDefault()
            X_FOR_CLOSE
          h1 {}, 'Congratulations!'
          p {},
            if @props.color == 'blue'
              'You predicted the output correctly!'
            else if @props.color == 'red'
              'You fixed the bug so all the tests pass!'
            else if @props.color == 'green'
              'You got all the tests passing!'
          button
            className: 'do-another'
            disabled: @props.doCommand.nextRep == null
            onClick: (e) => @props.doCommand.nextRep e, true
            "#{RELOAD_ICON} Do another"
          br {}
          button
            className: 'go-on'
            disabled: @props.doCommand.next == null
            onClick: (e) => @props.doCommand.next e
            "#{RIGHT_ARROW} Go on"

      if false && @props.popup == 'FAILED'
        div
          className: 'popup failed'
          a
            className: 'close-button'
            href: '#'
            onClick: (e) =>
              @props.doCommand.closePopup()
              e.preventDefault()
            X_FOR_CLOSE
          h1 {}, 'Not quite'
          p {}, 'Compare the actual output to see what you missed.'
          button
            className: 'do-another'
            disabled: @props.doCommand.nextRep == null
            onClick: (e) => @props.doCommand.nextRep e, false
            "#{RELOAD_ICON} Try another"

module.exports = ExerciseComponent
