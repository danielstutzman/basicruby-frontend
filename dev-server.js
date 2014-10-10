var http = require('http');
var fs = require('fs');
var path = require('path');

http.createServer(function (request, response) {
  var filePath = '.' + request.url;
  if (filePath == './') {
    filePath = './index.html';
  }

  var extname = path.extname(filePath);
  var contentType = 'text/html';
  switch (extname) {
    case '.js':   contentType = 'text/javascript';          break;
    case '.css':  contentType = 'text/css';                 break;
    case '.gif':  contentType = 'image/gif';                break;
    case '.jpg':  contentType = 'image/jpeg';               break;
    case '.jpeg': contentType = 'image/jpeg';               break;
    case '.ttf':  contentType = 'application/octet-stream'; break;
  }
  
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
  
}).listen(8000);

console.log('Server running at http://127.0.0.1:8000/');
