class ApiService

  constructor: (apiHost) ->
    @rpc = new easyXDM.Rpc({ remote: "http://#{apiHost}/easyxdm.html" },
      { remote: { request: {} } })

  _request: (method, url, data, callback) ->
    success = (result) ->
      data = JSON.parse(result.data)
      callback data
    error = (result) ->
      console.error result
      if result.data && result.data.data
        window.alert result.data.data
      else if result.data
        window.alert result.data
      else
        window.alert result
    @rpc.request { method, url, data }, success, error

  getMenu: (callback) ->
    @_request 'GET', '/api/menu.json', {}, callback

  getTutorMenu: (callback) ->
    @_request 'GET', '/api/tutor.json', {}, callback

  getTutorExercise: (taskId, callback) ->
    @_request 'GET', "/api/tutor/exercise/#{taskId}.json", {}, callback

  getExercise: (path, callback) ->
    @_request 'GET', "/api/exercise#{path}.json", {}, callback

  markComplete: (exerciseId, callback) =>
    @_request 'POST', "/api/mark_complete.json",
      { exercise_id: exerciseId }, callback

module.exports = ApiService
