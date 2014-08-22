AstToBytecodeCompiler = require './AstToBytecodeCompiler'
BytecodeInterpreter   = require './BytecodeInterpreter'
BytecodeSpool         = require './BytecodeSpool'
DebuggerController    = require './DebuggerController'
ExerciseComponent     = require './ExerciseComponent'

class ExerciseController
  constructor: ($div, service) ->
    @$div            = $div
    @service         = service
    @retrieveNewCode = null
    @popup           = null

  setup: =>
    success = (model) =>
      @_setupInstanceVarsFromModel model
      @render @_setupCodeMirrorAfterRender
    @service.getModel().then success, @_handleAjaxError

  _setupInstanceVarsFromModel: (model) =>
    @model = model
    exists = (feature) -> feature in model.features
    @features =
      showStepButton:   exists 'step'
      showRunButton:    exists 'run'
      showPartialCalls: exists 'partial_calls'
      showVariables:    exists 'vars'
      showHeapToggle:   exists 'heap_toggle'
      showInstructions: exists 'instructions'
      showConsole:      exists 'console'
      highlightTokens:  exists 'tokens'
    @cases               = @model.json.cases || [{}]

  _setupCodeMirrorAfterRender: =>
    options =
      mode: 'ruby'
      lineNumbers: true
      autofocus: true
      readOnly: false
    textarea = @$div.querySelector('textarea.code')
    isMobileSafari = ->
       navigator.userAgent.match(/(iPod|iPhone|iPad)/) &&
       navigator.userAgent.match(/AppleWebKit/)
    if isMobileSafari()
      @retrieveNewCode = -> textarea.value
    else
      codeMirror = CodeMirror.fromTextArea textarea, options
      makeRetriever = (codeMirror) -> (-> codeMirror.getValue())
      @retrieveNewCode = makeRetriever codeMirror

    if @cases && @cases[0] && @cases[0].code
      for textareaTests in @$div.querySelectorAll('textarea.expected')
        options =
          mode: 'ruby'
          lineNumbers: true
          readOnly: 'nocursor'
          lineWrapping: true
        CodeMirror.fromTextArea textareaTests, options

  render: (callback) ->
    props =
      code: @model.json.code || ''
      color: @model.color
      cases: @cases
      popup: @popup
      doCommand:
        run: =>
          @handleRun()
          @checkForPassingTests()
        debug: => @handleDebug()
        allTestsPassed: => window.setTimeout (=> @handleAllTestsPassed()), 100
        next: if @model.paths.next_exercise == '' then null else (e) =>
          e.target.disabled = true
          @_sendPostMarkComplete @model.paths.next_exercise
        nextRep: if @model.paths.next_rep == '' then null else (e, success) =>
          e.target.disabled = true
          if success
            @_sendPostMarkComplete @model.paths.next_rep
          else
            window.location.href = '#' + @model.paths.next_rep
        showSolution: => @handleShowSolution()
        closePopup: => @popup = null; @render()
        setPredictedOutput: (caseNum, newText) =>
          @cases[caseNum].predicted_output = newText
          @render()
          isCaseFinished = (case_) -> case_.predicted_output != undefined &&
                                      case_.actual_output != undefined
          if _.every @cases, isCaseFinished
            @checkForPassingTests()
    React.renderComponent ExerciseComponent(props), @$div, callback

  handleRun: ->
    code = @retrieveNewCode()
    allTestCode = _.map(@cases, (case_) -> case_.code || '').join('')
    for case_ in @cases
      case_.inputLineNum = 0
      try
        if case_.code
          match = /^def (test_[a-zA-Z0-9_]*)\n/.exec case_.code
          throw "Case doesn't start with def test_" if match == null
          test_name = match[1]
          bytecodes = AstToBytecodeCompiler.compile [
            ['YourCode', code],
            ['TestCode', allTestCode],
            ['Main', "__run_test(:#{test_name})"]
          ]
        else
          bytecodes = AstToBytecodeCompiler.compile [['YourCode', code]]
      catch e
        if e.name == 'SyntaxError'
          case_.actual_output = [['stderr', "SyntaxError: #{e.message}\n"]]
        else if e.name == 'DebuggerDoesntYetSupport'
          case_.actual_output =
            [['stderr', "DebuggerDoesntYetSupport: #{e.message}\n"]]
        else
          throw e

      if bytecodes
        @spool = new BytecodeSpool bytecodes
        @interpreter = new BytecodeInterpreter()
        @spool.queueRunUntil 'DONE'
        i = 0
        until @spool.isDone()
          i += 1
          if i > 10000
            throw "Interpreter seems to be stuck in a loop"
          bytecode = @spool.getNextBytecode()
          try
            spoolCommand = @interpreter.interpret bytecode
            @spool.doCommand.apply @spool, spoolCommand
          catch e
            if e.name == 'ProgramTerminated'
              @interpreter.undefineMethods()
              @spool.terminateEarly()
            else
              throw e
          if @interpreter.isAcceptingInput()
            line = case_.input.toString().split("\n")[case_.inputLineNum] + "\n"
            @interpreter.setInput line
            case_.inputLineNum += 1
        case_.actual_output = @interpreter.getStdoutAndStderr()
    @render()

  handleDebug: ->
    features = _.extend @features, showNextExercise: false, showNextRep: false,
      showingSolution: false
    @_popupDebugger @retrieveNewCode(), features, {}

  handleShowSolution: ->
    features = _.extend @features,
      showNextExercise: false
      showNextRep: @model.paths.next_rep != ''
      showingSolution: true
    doCommand =
      nextExercise: (e) =>
        e.target.disabled = true
        window.location.href = '#' + @model.paths.next_exercise
      nextRep: (e) =>
        e.target.disabled = true
        window.location.href = '#' + @model.paths.next_rep
    @_popupDebugger @model.json.solution, features, doCommand

  _popupDebugger: (code, features, doCommand) ->
    newDiv = document.createElement('div')
    newDiv.className = 'debugger'
    document.body.appendChild newDiv
    new DebuggerController(code, newDiv, features, @model.json, doCommand \
      ).setup()

  checkForPassingTests: ->
    rtrim = (s) -> if s then s.replace(/\s+$/, '') else s
    join = (outputs) ->
      _.map(outputs, ((output) -> output[1])).join('')
    for case_, case_num in @cases
      case_.passed =
        if @model.color == 'blue'
          rtrim(join(case_.actual_output)) == rtrim(case_.predicted_output)
        else if @model.color == 'red' || @model.color == 'green'
          if case_.expected_output
            rtrim(join(case_.actual_output)) ==
              rtrim(case_.expected_output.toString())
          else if case_.code && case_.actual_output.length > 0
            firstLine = case_.actual_output[0][1]
            /^test[a-zA-Z0-9_]+ PASSED\n/.exec(firstLine)
    passed = _.every(@cases, (case_) -> case_.passed)
    changeBackground = (i, selector, popup) =>
      for span in document.querySelectorAll(selector)
        span.style.opacity = if (i % 2 == 0) then '1.0' else '0.0'
      if i > 0
        window.setTimeout (-> changeBackground(i - 1, selector, popup)), 300
      else
        @popup = popup
        @render()
    if passed
      changeBackground 5, '.passed', 'PASSED'
    else if !passed && @model.color == 'blue'
      changeBackground 5, '.failed', 'FAILED'

  _sendPostMarkComplete: (nextUrl) =>
    promise = @service.markComplete @model.exercise_id
    promise.then (-> window.location.href = '#' + nextUrl), @_handleAjaxError

  _handleAjaxError: (request) ->
    console.error JSON.parse(request.responseText)
    window.alert "#{request.status} #{request.statusText}"

module.exports = ExerciseController
