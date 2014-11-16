ApiService            = require './ApiService'
AstToBytecodeCompiler = require './AstToBytecodeCompiler'
Router                = require './Router'
REQUIRE               = require './REQUIRE'

if window.location.hostname == 'localhost'
  window.onerror = (message, url, lineNumber) ->
    document.querySelector('#throbber').style.display = 'none'
    window.alert "See console: #{message} at #{url}:#{lineNumber}"

unless window.location.pathname == '/test.html'
  if typeof(apiHost) == 'undefined'
    window.alert 'Missing global variable: apiHost'

  timeout = window.setTimeout (-> throw "Timeout contacting API server"), 5000
  socketConfig =
    remote: "http://#{apiHost}/easyxdm.html"
    onReady: -> window.clearTimeout timeout
    channel: "999" # keep xdm_c GET param the same so easyxdm can be cached
  rpc = new easyXDM.Rpc(socketConfig, { remote: { request: {} } })

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
