class ExerciseService

  constructor: (baseUrl, path) ->
    @baseUrl = baseUrl
    @path = path

  getModel: =>
    window.reqwest "#{@baseUrl}/api/exercise#{@path}.json"

  markComplete: (exerciseId) =>
    window.reqwest
      url: "#{@baseUrl}/api/mark_complete.json"
      data: { exercise_id: exerciseId }
      method: 'post'

module.exports = ExerciseService
