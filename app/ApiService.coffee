class ApiService

  constructor: (rpc) ->
    @rpc = rpc

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

    if method == 'GET'
      pairs = []
      for own key of data
        pairs.push "#{encodeURIComponent(key)}=#{encodeURIComponent(data[key])}"
      dataEncoded = pairs.join('&')
    else if method == 'POST'
      dataEncoded = JSON.stringify(data)

    headers = { 'Content-Type': 'application/json' }
    config = { method, url, data: dataEncoded, headers }
    @rpc.request config, success, error

  getAllExercises: (callback) ->
    @_request 'GET', '/api/all_exercises.json', {}, callback

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

  saveTutorCode: (taskId, newCode, callback) ->
    @_request 'POST', '/api/tutor/save_tutor_code.json',
      { task_id: taskId, user_code_textarea: newCode }, callback

  discardTutorCode: (taskId, callback) ->
    @_request 'POST', '/api/tutor/discard_tutor_code.json',
      { task_id: taskId }, callback

module.exports = ApiService
