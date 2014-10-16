var http = require('http');
var fs = require('fs');
var path = require('path');

var MIME_TYPES = {
  '.js':   'text/javascript',
  '.css':  'text/css',
  '.gif':  'image/gif',
  '.jpg':  'image/jpeg',
  '.jpeg': 'omage/jpeg',
  '.ttf':  'application/octet-stream',
  '.png':  'image/png',
};

var walk = function (dir, handleFile, done) {
    fs.readdir(dir, function (error, list) {
        if (error) {
            return done(error);
        }

        var i = 0;

        (function next () {
            var file = list[i++];

            if (!file) {
                return done(null);
            }

            file = dir + '/' + file;

            fs.stat(file, function (error, stat) {
                if (stat && stat.isDirectory()) {
                    walk(file, handleFile, function (error) {
                        next();
                    });
                } else {
                    try {
                        handleFile(file, stat, next);
                    } catch (e) {
                        done(e);
                    }
                }
            });
        })();
    });
};

function browserifiedServe(filePath, request, response) {
  fs.stat(filePath, function(error, stat) {
    var compiledMtime = stat.mtime;
    function complainIfCoffeeTimestampTooLate(path, stat, callback) {
      if (compiledMtime < stat.mtime && path.match(/\.(coffee|js)$/)) {
        throw { message: "Path " + path + " is newer than " + filePath + "!" };
      }
      else {
        callback();
      }
    }
    walk('../app/', complainIfCoffeeTimestampTooLate, function(error) {
      if (error) {
        console.error(error);
        var content = "alert('" + JSON.stringify(error) + "');";
        console.log('200 ' + request.url);
        response.writeHead(200, { 'Content-Type': 'text/javascript' });
        response.end(content, 'utf-8');
      } else {
        fs.readFile(filePath, function(error, content) {
          console.log('200 ' + request.url);
          response.writeHead(200, { 'Content-Type': 'text/javascript' });
          response.end(content, 'utf-8');
        });
      }
    });
  });
}

function normalServe(filePath, request, response) {
  var extname = path.extname(filePath);
  var contentType = MIME_TYPES[extname] || 'text/html';

  fs.exists(filePath, function(exists) {
    if (exists) {
      fs.readFile(filePath, function(error, content) {
        if (error) {
          console.log('500 ' + request.url);
          response.writeHead(500, { 'Content-Type': 'text/html' });
          response.end(error, 'utf-8');
        }
        else {
          console.log('200 ' + request.url);
          response.writeHead(200, { 'Content-Type': contentType });
          response.end(content, 'utf-8');
        }
      });
    }
    else {
      console.log('200 #' + request.url);
      response.writeHead(200, { 'Content-Type': contentType });
      var content = '<script>window.location = "/#' + request.url + '"</script>';
      response.end(content, 'utf-8');

//      console.log('404 ' + request.url);
//      response.writeHead(404, { 'Content-Type': 'text/html' });
//      response.end('404', 'utf-8');
    }
  });
}

http.createServer(function (request, response) {
  var filePath = '.' + request.url;
  if (filePath == './') {
    filePath = './index.html';
  }

  if (request.url == '/javascripts/browserified.js') {
    browserifiedServe(filePath, request, response);
  }
  else {
    normalServe(filePath, request, response);
  }

}).listen(8000);

console.log('Server running at http://127.0.0.1:8000/');
