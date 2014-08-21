class ExerciseService

  constructor: (baseUrl) ->
    @baseUrl = baseUrl

  getModel: =>
    window.reqwest "#{@baseUrl}/api/exercise/1Y.json"

  markComplete: (exerciseId) =>
    window.reqwest
      url: "#{@baseUrl}/api/mark_complete.json"
      data: { exercise_id: exerciseId }
      method: 'post'

module.exports = ExerciseService
