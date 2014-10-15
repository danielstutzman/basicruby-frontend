fs            = require 'fs'
http          = require 'http'
mkdir         = require 'mkdir'
path_         = require 'path'
global.React  = require 'react'
_             = require 'underscore'
ApiService    = require './build/coffee/app/ApiService'
Router        = require './build/coffee/app/Router'
Entities      = require('html-entities').AllHtmlEntities

# fake object is necessary global
global.History = {}

rpc =
  request: (config, success, error) ->
    options =
       method:   config.method
       hostname: 'localhost'
       port:     9292
       path:     config.url
    request = http.request options, (response) ->
      response.setEncoding 'utf8'
      dataSoFar = ''
      response.on 'data', (data) ->
        dataSoFar += data.toString()
      response.on 'end', (data) ->
        result = { data: dataSoFar }
        success(result)
      response.on 'error', (e) ->
        throw new "problem with request: #{e.message}"
    request.end()

service = new ApiService(rpc)
router = new Router(service)
render = (path) ->
  router.render path, (reactComponent, callbackIgnored) ->
    outerHtml  = fs.readFileSync('dist/index-outer.html').toString()
    menuHtml   = React.renderComponentToString(reactComponent)
    beforeHtml = outerHtml.replace /<!-- START PRE-RENDERED CONTENT -->([^]*)/, ''
    afterHtml  = outerHtml.replace /([^]*)<!-- END PRE-RENDERED CONTENT -->/, ''
    outputHtml = beforeHtml +
      (new Entities()).encodeNonASCII(menuHtml) + afterHtml
    pathOnDisk = "dist#{path}/index.html"

    console.log pathOnDisk
    mkdir.mkdirsSync path_.dirname(pathOnDisk)
    fs.writeFileSync pathOnDisk, outputHtml

for path in ['/', '/tutor', '/1Y', '/tutor/exercise/D001']
  render path
