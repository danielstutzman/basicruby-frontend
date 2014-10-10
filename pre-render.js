fs            = require('fs');
http          = require('http');
React         = require('react');
_             = require('underscore');
ApiService    = require('./build/coffee/app/ApiService');
MenuComponent = require('./build/coffee/app/MenuComponent');
                require('./build/coffee/app/application');
Entities      = require('html-entities').AllHtmlEntities;

// fake object is necessary global
History = {};

rpc = {
  request: function(config, success, error) {
    var options = {
       method:   config.method,
       hostname: 'localhost',
       port:     9292,
       path:     config.url,
    };
    var request = http.request(options, function(response) {
      response.setEncoding('utf8');
      dataSoFar = '';
      response.on('data', function(data) {
        dataSoFar += data.toString();
      });
      response.on('end', function(data) {
        result = { data: dataSoFar };
        success(result);
      });
      response.on('error', function(e) {
        throw new('problem with request: ' + e.message);
      });
    });
    request.end();
  }
};
var service = new ApiService(rpc);
service.getMenu(function(data) {
  var outerHtml  = fs.readFileSync('dist/index-outer.html').toString();
  var menuHtml   = React.renderComponentToString(MenuComponent(data));
  var beforeHtml = outerHtml.replace(
    /<!-- START PRE-RENDERED CONTENT -->([^]*)/, '');
  var afterHtml  = outerHtml.replace(
    /([^]*)<!-- END PRE-RENDERED CONTENT -->/, '');
  var outputHtml = beforeHtml +
    (new Entities()).encodeNonASCII(menuHtml) + afterHtml;
  fs.writeFileSync('dist/index.html', outputHtml);
});
