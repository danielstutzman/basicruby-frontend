ExerciseComponent     = require './ExerciseComponent'

class ExerciseController
  constructor: (service, reactRender, path) ->
    @service         = service
    @reactRender     = reactRender
    @path            = path
    @popup           = null

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
    console.log 'handleRun'
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
