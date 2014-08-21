class ExerciseService

  constructor: (baseUrl) ->
    @baseUrl = baseUrl

  getModel: (callback) =>
    window.reqwest "#{@baseUrl}/api/exercise/1Y.json", callback

module.exports = ExerciseService
