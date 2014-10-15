fs            = require 'fs'
http          = require 'http'
global.React  = require 'react'
_             = require 'underscore'
ApiService    = require './build/coffee/app/ApiService'
MenuComponent = require './build/coffee/app/MenuComponent'
application   = require './build/coffee/app/application'
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
service.getMenu (data) ->
  outerHtml  = fs.readFileSync('dist/index-outer.html').toString()
  menuHtml   = React.renderComponentToString(MenuComponent(data))
  beforeHtml = outerHtml.replace /<!-- START PRE-RENDERED CONTENT -->([^]*)/, ''
  afterHtml  = outerHtml.replace /([^]*)<!-- END PRE-RENDERED CONTENT -->/, ''
  outputHtml = beforeHtml +
    (new Entities()).encodeNonASCII(menuHtml) + afterHtml
  fs.writeFileSync 'dist/index.html', outputHtml
