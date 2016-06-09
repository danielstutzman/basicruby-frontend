ApiService        = require './ApiService.coffee'
ReactAddonsUpdate = require 'react-addons-update'
ReactDOM          = require 'react-dom'
Redux             = require 'redux'
Router            = require './Router'

if window.location.hostname == 'localhost'
  window.onerror = (message, url, lineNumber) ->
    document.querySelector('#throbber').style.display = 'none'
    window.alert "See console: #{message} at #{url}:#{lineNumber}"

unless window.location.pathname == '/test.html'
  rpc =
    request: (config, success, error) ->
      xhr = new XMLHttpRequest()
      xhr.addEventListener 'load', ->
        if this.status == 200
          success { data: this.responseText }
        else
          error { data: this.responseText }
      xhr.addEventListener 'error', -> error()
      xhr.open config.method, config.url
      for own key, value of config.headers
        xhr.setRequestHeader key, value
      xhr.send config.data

service = new ApiService rpc, (showThrobber) ->
  document.querySelector('#throbber').style.display =
    (if showThrobber then 'block' else 'none')

stringifyState = (object) ->
  if object is null
    'null'
  else if typeof(object) is 'object'
    keys = Object.keys(object).sort()
    out = "{"
    for key in keys
      value = object[key]
      if out != '{'
        out += ' '
      out += "#{key}:#{stringifyState(value)}"
    out += "}"
    out
  else
    "#{object}"

document.addEventListener 'DOMContentLoaded', ->
  reducer = (state, action) ->
    console.log 'action', stringifyState(action)
    update = (commands) -> ReactAddonsUpdate state, commands
    switch action.type
      when '@@redux/INIT' then state
      when 'MOVE_NODE'
        update nodesInWorkspace: "#{action.nodeNum}":
          leftX: $set: action.leftX
          topY: $set: action.topY
      when 'MOVE_TARGET'
        update nodesInWorkspace: "#{action.nodeNum}":
          target: $set: action.target
      else throw new Error("Unknown action type #{action.type}")
  store = Redux.createStore reducer,
    nodesInWorkspace: [
      { leftX: 10,  topY: 0, type: '+', target: null },
      { leftX: 40, topY: 100, type: '-', target: null }]

  router = new Router(service, store)
  window.history.pathChanged = (path) ->
    router.render path, (reactComponent, callMeAfterRender) ->
      ReactDOM.render reactComponent,
        document.querySelector('#screen'),
        callMeAfterRender

  window.onpopstate = (event) ->
    window.history.pathChanged window.location.pathname
  window.onpopstate null # handle current GET params

  window.history.onClick = (e) ->
    e.preventDefault() # don't re-request page by following clicked <a> link
    # Use currentTarget instead of target for when there's an a tag around a div
    href = e.currentTarget.getAttribute('href')
    window.history.pushState null, null, href
    window.history.pathChanged href

  # Fix bug where Mobile Safari landscape mode scrolls too far down the page
  window.addEventListener 'orientationchange', ->
    window.scrollTo 0, 1
