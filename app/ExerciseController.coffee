ExerciseComponent     = require './ExerciseComponent'
BasicRubyNew          = require './BasicRubyNew'

class ExerciseController
  constructor: (service, reactRender, path) ->
    @service         = service
    @reactRender     = reactRender
    @path            = path
    @popup           = null
    @traceContents   = []

  setup: =>
    @service.getExercise @path, (model) =>
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
      cases:        @cases
      popup:        @popup
      youtubeId:    @model.json.youtube_id
      videoScript:  @model.json.video_script
      traceContents:@traceContents
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
            window.history.pushState null, null, @model.paths.next_rep
            window.history.pathChanged @model.paths.next_rep
        showSolution: => @handleShowSolution()
        closePopup: => @handleClosePopup()
        setPredictedOutput: (caseNum, newText) =>
          @cases[caseNum].predicted_output = newText
          @render()
          isCaseFinished = (case_) -> case_.predicted_output != undefined &&
                                      case_.actual_output != undefined
          if _.every @cases, isCaseFinished
            @checkForPassingTests()
    @reactRender ExerciseComponent(props), callback

  handleClosePopup: ->
    if @popup != null
      @popup = null
      @render()

  handleRun: (code) ->
    @traceContents = []
    textMarkers = []
    highlight = (codeMirror, replacements) ->
      for replacement, i in replacements
        #console.log "replacement #{i}", replacement
        replacedWith = null
        if replacement.expr
          exprType = document.createElement 'span'
          exprType.setAttribute 'style', 'font-size: 8pt; position: absolute; top: -5px'
          exprType.appendChild document.createTextNode replacement.expr.$class()
          replacedWith = document.createElement 'span'
          replacedWith.setAttribute 'style', 'background-color: blue; color: white'
          replacedWith.appendChild exprType
          replacedWith.appendChild document.createTextNode replacement.expr.$inspect()
        textMarker = codeMirror.getDoc().markText { line: replacement.row0 - 1, ch: replacement.col0 },
          { line: replacement.row1 - 1, ch: replacement.col1 },
          { className: 'highlighted', replacedWith: replacedWith }
        textMarkers.push textMarker

    idToSavedValue = {}
    replacements = []
    resultReplacement = null
    methodNameToDefRange = {}
    indentation = 0
    callback = (name, row0, col0, row1, col1, methodReceiverId, methodName,
        methodArgumentIds, saveAsId, expr, consoleTexts) =>
      idToSavedValue[saveAsId] = expr
      indentationIncrease = 0

      output = ''
      for eachOutput in consoleTexts
        output += eachOutput[1]
      consoleTexts.length = 0

      highlighting      = { row0, col0, row1, col1 }
      resultReplacement = { row0, col0, row1, col1, expr }

      if name == 'str'
        log = 'Evaluate string literal'
      else if name == 'int'
        log = 'Evaluate number literal'
      else if name == 'call'
        if methodNameToDefRange[methodName]
          log = "Return"
          indentationIncrease = -1
          resultReplacement = { row0, col0, row1, col1, expr }

          # Hack: show line num for the last statement executed (presumably the
          # return) instead of the line num for the method call
          lastReplacement = replacements[replacements.length - 1]
          highlighting =
            row0: lastReplacement.row0
            col0: lastReplacement.col0
            row1: lastReplacement.row1
            col1: lastReplacement.col1
        else
          log = "Call <code>#{methodName}</code> method"
          if methodReceiverId && methodReceiverId != 4
            log += " on <code>#{idToSavedValue[methodReceiverId].$inspect()}</code>"
          if methodArgumentIds
            if methodArgumentIds.length == 0
              log += " with no arguments"
            else if methodArgumentIds.length == 1
              log += " with argument "
            else
              log += " with arguments "

            for methodArgumentId, i in methodArgumentIds
              log += ", " if i > 0
              log += "<code>#{idToSavedValue[methodArgumentId].$inspect()}</code>"
      else if name == 'js_return'
        return
      else if name == 'def'
        log = "Define <code>#{methodName}</code> method"
        resultReplacement = null
        methodNameToDefRange[methodName] = { row0, col0, row1, col1 }
        expr = null # otherwise Opal returns "f" from (def f(x); end)
      else if name == 'lvar'
        log = "Evaluate <code>#{methodName}</code> variable"
      else if name == 'start_call'
        if methodNameToDefRange[methodName]
          log = "Call <code>#{methodName}</code> method"
          if methodReceiverId && methodReceiverId != 4
            log += " on <code>#{idToSavedValue[methodReceiverId].$inspect()}</code>"
          if methodArgumentIds
            if methodArgumentIds.length == 0
              log += " with no arguments"
            else if methodArgumentIds.length == 1
              log += " with argument "
            else
              log += " with arguments "

            for methodArgumentId, i in methodArgumentIds
              log += ", " if i > 0
              log += "<code>#{idToSavedValue[methodArgumentId].$inspect()}</code>"
          resultReplacement = null
          indentationIncrease = 1
          expr = null # expr isn't the real return yet, just the last arg
        else
          # EARLY RETURN: ignore start_call for methods we haven't defined
          #   because we want to show the return value
          return
      else
        log = "got #{name}"

      replacementsCopy1 = replacements.concat([highlighting])
      replacementsCopy2 = replacements.concat(
        if resultReplacement then [resultReplacement] else [])
      replaceCallback = (codeMirror) ->
        highlight codeMirror, replacementsCopy1
      replaceResultCallback = (codeMirror) ->
        highlight codeMirror, replacementsCopy2
      clearCallback = (codeMirror) ->
        for textMarker in textMarkers
          textMarker.clear()
        textMarkers = []
      @traceContents.push [indentation, highlighting.row0, log, replaceCallback,
        replaceResultCallback, clearCallback, expr, output]

      if name == 'call'
        # Now that the method has been called, remove all the replacements in it
        # so it can be called later with fresh values
        defRange = methodNameToDefRange[methodName]
        if defRange
          newReplacements = []
          for replacement in replacements
            if replacement.row0 < defRange.row0 or \
                replacement.row0 == defRange.row0 and \
                replacement.col0 < defRange.col0 or \
                replacement.row1 > defRange.row1 or \
                replacement.row1 == defRange.row1 and \
                replacement.col1 > defRange.col1
              newReplacements.push replacement
          replacements = newReplacements


      indentation += indentationIncrease
      replacements.push resultReplacement if resultReplacement

    BasicRubyNew.runRubyWithHighlighting code, callback
    @render()

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
    @render()
    @service.markComplete @model.exercise_id, ->
      window.history.pushState null, null, nextUrl
      window.history.pathChanged nextUrl

module.exports = ExerciseController
