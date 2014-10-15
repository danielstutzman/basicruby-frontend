fs            = require 'fs'
http          = require 'http'
mkdir         = require 'mkdir'
path_         = require 'path'
htmlparser2   = require 'htmlparser2'
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
render = (path, callback) ->
  router.render path, (reactComponent, callbackIgnored) ->
    outerHtml  = fs.readFileSync('dist/index-outer.html').toString()
    innerHtml  = React.renderComponentToString(reactComponent)
    beforeHtml = outerHtml.replace /<!-- START PRE-RENDERED CONTENT -->([^]*)/, ''
    afterHtml  = outerHtml.replace /([^]*)<!-- END PRE-RENDERED CONTENT -->/, ''
    outputHtml = beforeHtml +
      (new Entities()).encodeNonASCII(innerHtml) + afterHtml
    pathOnDisk = "dist#{path}/index.html"

    console.log pathOnDisk
    mkdir.mkdirsSync path_.dirname(pathOnDisk)
    fs.writeFileSync pathOnDisk, outputHtml
    callback()

scrapeTutorForPaths = (callbackWithTutorPaths) ->
  router.render '/tutor', (reactComponent, callbackIgnored) ->
    html = React.renderComponentToString(reactComponent)

    paths = []
    parser = new htmlparser2.Parser
      onopentag: (name, attributes) ->
        if name == 'a'
          paths.push attributes.href
    parser.write html
    parser.end()

    callbackWithTutorPaths paths

gatherAllPaths = (callbackWithAllPaths) ->
  paths = ['/', '/tutor']
  service.getAllExercises (data) ->
    for exercise in data
      color = exercise.color.substring(0, 1).toUpperCase()
      if exercise.rep_num == 1
        path = "/#{exercise.topic_num}#{color}"
      else
        path = "/#{exercise.topic_num}#{color}/#{exercise.rep_num}"
      paths.push path
  scrapeTutorForPaths (tutorPaths) ->
    callbackWithAllPaths paths.concat(tutorPaths)

renderSitemap = (paths) ->
  content = _.map(paths, (path) -> "http://www.basicruby.com#{path}").join("\n")
  console.log 'dist/sitemap.txt'
  fs.writeFileSync 'dist/sitemap.txt', content

gatherAllPaths (paths) ->
  renderSitemap(paths)

  renderPaths = (paths) ->
    nextPath = paths.shift()
    render nextPath, ->
      renderPaths paths
  renderPaths paths
