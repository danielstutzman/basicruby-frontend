AstToBytecodeCompiler = require './AstToBytecodeCompiler'
BytecodeInterpreter   = require './BytecodeInterpreter'
BytecodeSpool         = require './BytecodeSpool'
DebuggerController    = require './DebuggerController'
ExerciseComponent     = require './ExerciseComponent'

class ExerciseController
  constructor: ($div, service) ->
    @$div            = $div
    @service         = service
    @popup           = null
    @waitingForAjax  = true

  setup: =>
    @service.getModel (model) =>
      @waitingForAjax = false
      @_setupInstanceVarsFromModel model
      @render()

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

  render: (callback) ->
    props =
      initialCode:  @model.json.code || '' # green exercises don't have code
      color:        @model.color
      topicNum:     @model.topic.num
      topicTitle:   @model.topic.title
      showThrobber: @waitingForAjax
      cases:        @cases
      popup:        @popup
      youtubeId:    @model.json.youtube_id
      videoScript:  @model.json.video_script
      doCommand:
        run: (code) =>
          @handleRun code
          @checkForPassingTests()
        debug: (code) => @handleDebug code
        allTestsPassed: => window.setTimeout (=> @handleAllTestsPassed()), 100
        next: @model.paths.next_exercise && (e) =>
          e.target.disabled = true
          @_sendPostMarkComplete @model.paths.next_exercise
        nextRep: @model.paths.next_rep && (e, solvedExercise) =>
          e.target.disabled = true
          if solvedExercise
            # mark complete and go on
            @_sendPostMarkComplete @model.paths.next_rep
          else
            # don't mark complete but still go on
            window.location.href = '#' + @model.paths.next_rep
        showSolution: => @handleShowSolution()
        closePopup: => @handleClosePopup()
        setPredictedOutput: (caseNum, newText) =>
          @cases[caseNum].predicted_output = newText
          @render()
          isCaseFinished = (case_) -> case_.predicted_output != undefined &&
                                      case_.actual_output != undefined
          if _.every @cases, isCaseFinished
            @checkForPassingTests()
    React.renderComponent ExerciseComponent(props), @$div, callback

  handleClosePopup: ->
    if @popup != null
      @popup = null
      @render()

  handleRun: (code) ->
    allTestCode = _.map(@cases, (case_) -> case_.code || '').join('')
    for case_ in @cases
      case_.inputLineNum = 0
      try
        if case_.code
          match = /^def (test[a-zA-Z0-9_]*)\n/.exec case_.code
          throw "Case doesn't start with def test" if match == null
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

  handleDebug: (code) ->
    features = _.extend @features, showNextExercise: false, showNextRep: false,
      showingSolution: false
    @_popupDebugger code, features, {}

  handleShowSolution: ->
    features = _.extend @features,
      showNextExercise: false
      showNextRep: @model.paths.next_rep != null
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
    for div in document.querySelectorAll('.debugger')
      div.style.display = 'block'
      new DebuggerController(code, div, features, @model.json, doCommand).setup()

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
    @waitingForAjax = true
    @render()
    @service.markComplete @model.exercise_id, =>
      window.location.href = '#' + nextUrl

module.exports = ExerciseController
