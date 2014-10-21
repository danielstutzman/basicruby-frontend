ApiService            = require './ApiService'
AstToBytecodeCompiler = require './AstToBytecodeCompiler'
Router                = require './Router'
REQUIRE               = require './REQUIRE'

if window.location.hostname == 'localhost'
  window.onerror = (message, url, lineNumber) ->
    window.alert "See console: #{message} at #{url}:#{lineNumber}"

if window.location.hostname == 'localhost'
  apiHost = 'localhost:9292'
else
  apiHost = 'basicruby.danstutzman.com'

unless window.location.pathname == '/test.html'
  rpc = new easyXDM.Rpc({ remote: "http://#{apiHost}/easyxdm.html" },
    { remote: { request: {} } })

service = new ApiService rpc, (showThrobber) ->
  document.querySelector('#throbber').style.display =
    (if showThrobber then 'block' else 'none')

router = new Router(service)
pathChanged = (path) ->
  router.render path, (reactComponent, callMeAfterRender) ->
    React.renderComponent reactComponent,
      document.querySelector('#screen'),
      callMeAfterRender

document.addEventListener 'DOMContentLoaded', ->
  window.History.Adapter.bind window, 'statechange', ->
    pathChanged History.getState().hash
  unless window.location.hash
    pathChanged window.location.pathname
  window.History.onClick = (e) ->
    e.preventDefault() # don't re-request page by following clicked <a> link
    # Use currentTarget instead of target for when there's an a tag around a div
    href = e.currentTarget.getAttribute('href')
    History.pushState null, null, href

  # Fix bug where Mobile Safari landscape mode scrolls too far down the page
  window.addEventListener 'orientationchange', ->
    window.scrollTo 0, 1

  AstToBytecodeCompiler.initCache()
