ApiService            = require './ApiService.coffee'
ReactDOM              = require 'react-dom'
Router                = require './Router'

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

router = new Router(service)
window.history.pathChanged = (path) ->
  router.render path, (reactComponent, callMeAfterRender) ->
    ReactDOM.render reactComponent,
      document.querySelector('#screen'),
      callMeAfterRender

document.addEventListener 'DOMContentLoaded', ->
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
