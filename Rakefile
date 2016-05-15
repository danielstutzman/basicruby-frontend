def create_with_sh command, path
  begin
    sh "#{command} > #{path}"
  rescue
    sh "rm -f #{path}"
    raise
  end
end

directory 'build/javascripts'
directory 'build/stylesheets'

file 'build/index.html' do |task|
  sh "ln -s ../app/index.html #{task.name}"
end

file 'build/images' do |task|
  sh "ln -s ../app/images #{task.name}"
end

file 'build/javascripts/vendor.js' => %w[build/javascripts] do |task|
  begin
    sh "rm -f #{task.name}"
    sh "cat node_modules/react/dist/react.min.js >> #{task.name}"
    sh "cat node_modules/underscore/underscore-min.js >> #{task.name}"
    sh "echo >> #{task.name}" # needs a newline if anything follows
    sh "echo 'module = {};' >> #{task.name}"
    sh "cat node_modules/easyxdm/lib/easyXDM.js >> #{task.name}"
    sh "echo 'window.EasyXDM = module.exports; delete window.module;' >> #{task.name}"
    sh "cat node_modules/opal/opal.js >> #{task.name}"
    sh "cat node_modules/basicruby-interpreter/dist/basicruby-interpreter.js >> #{task.name}"
    sh "cat node_modules/codemirror/lib/codemirror.js >> #{task.name}"
    sh "cat node_modules/codemirror/mode/ruby/ruby.js >> #{task.name}"
  rescue
    sh "rm -f #{task.name}"
    raise
  end
end

desc 'Compile app/*.coffee to build/javascripts/browserified.js with inline source'
file 'build/javascripts/browserified.js' =>
    ['build/javascripts'] + Dir.glob('app/*.coffee') do |task|
  create_with_sh "node_modules/.bin/browserify \
    -t coffeeify app/application.coffee -d --extension=.coffee \
    -x react -x react-dom -x underscore -x bluebird -x react-addons-update -x redux -x opal \
    -x basicruby-interpreter -x easyxdm \
    -v -o #{task.name}", task.name
end

desc 'Compile app/*.coffee to build/javascripts/browserified.js incrementally with inline source'
task :watch_coffee => %w[build/javascripts] do
  sh "node_modules/watchify/bin/cmd.js \
    -t coffeeify app/application.coffee -d --extension=.coffee \
    -x react -x react-dom -x underscore -x bluebird -x react-addons-update -x redux -x opal \
    -x basicruby-interpreter -x easyxdm \
    -v -o build/javascripts/browserified.js"
end

file 'build/stylesheets/all.css' => %w[build/stylesheets] do |task|
  sh "sass --update app/stylesheets:build/stylesheets --sourcemap=none"
  create_with_sh "cat build/stylesheets/*.css node_modules/codemirror/lib/codemirror.css",
    task.name
end

task :serve_build => :build_all do
  require 'webrick' # require inside block to save time
  class NonCachingFileHandler < WEBrick::HTTPServlet::FileHandler
    def do_GET request, response
      super
      response['Cache-Control'] = 'no-cache, must-revalidate'
    end
  end
  server = WEBrick::HTTPServer.new BindAddress: '127.0.0.1', Port: 3000,
    AccessLog: [[$stderr, '%t %s %m %U']]
  server.mount '/', NonCachingFileHandler , 'build'
  trap 'INT' do exit! 1 end
  server.start
end

task :clean do
  sh 'rm -rf build dist'
end

task :build_all => %W[
  build
  build/index.html
  build/images
  build/stylesheets/all.css
  build/javascripts/browserified.js
  build/javascripts/vendor.js
]

directory 'dist/javascripts'
directory 'dist/stylesheets'
directory 'dist/images'

file 'build/stylesheets/all.dist.css' =>
    %w[build/stylesheets/all.css dist/assets.images.json] do |task|
  require 'json' # require inside block to save time
  assets = JSON.load(File.read('dist/assets.images.json'))
  assets.each { |key, value| value.gsub! 'dist/', '/' }

  css = File.read('build/stylesheets/all.css')
  css.gsub!(%r[url\("\.\.(.*)"\)]) { |path| "url(\"#{assets.fetch('build' + $1)}\")" } \
    or raise "Couldn't find <link> for /stylesheets/all.min.css"
  File.open(task.name, 'w') { |f| f.write css }
end

file 'build/stylesheets/all.min.css' => %w[build/stylesheets/all.dist.css] do |task|
  create_with_sh "node_modules/.bin/cssmin build/stylesheets/all.dist.css", task.name
end

file 'build/javascripts/browserified.min.js' => %w[build/javascripts/browserified.js] do |task|
  create_with_sh "cat build/javascripts/browserified.js | \
    node_modules/uglify-js/bin/uglifyjs -b 'ascii-only=true, beautify=false'",
    task.name
end

file 'build/javascripts/vendor.min.js' => %w[build/javascripts/vendor.js] do |task|
  create_with_sh "cat build/javascripts/vendor.js | \
    node_modules/uglify-js/bin/uglifyjs -b 'ascii-only=true, beautify=false'",
    task.name
end

file 'dist/assets.images.json' => %w[build/images dist/images] do
  image_paths = `find build/images/ -name "*.jpg"`.split("\n")
  image_paths += `find build/images/ -name "*.png"`.split("\n")
  raise "Can't find images" if image_paths.size == 0
  sh "node_modules/.bin/hashmark #{image_paths.join(' ')} \
    -l 5 -m dist/assets.images.json 'dist/images/{name}.{hash}{ext}'"
end

file 'dist/assets.json' => %w[
    build/stylesheets/all.min.css
    dist/stylesheets
    build/javascripts/browserified.min.js
    build/javascripts/vendor.min.js
    dist/javascripts
  ] do |task|

  all_css = task.prerequisites.select { |path| path.match(/\.css$/) }.join(' ')
  sh "node_modules/.bin/hashmark #{all_css} \
    -l 5 -m dist/assets.json 'dist/stylesheets/{name}.{hash}{ext}'"

  all_js = task.prerequisites.select { |path| path.match(/\.js$/) }.join(' ')
  sh "node_modules/.bin/hashmark #{all_js} \
    -l 5 -m dist/assets.json 'dist/javascripts/{name}.{hash}{ext}'"
end

task 'dist/index.html' => %w[app/index.html dist/assets.json] do |task|
  require 'json' # require inside block to save time
  assets = JSON.load(File.read('dist/assets.json'))
  assets.each { |key, value| value.gsub! 'dist/', '/' }

  index = File.read('app/index.html')
  index.gsub! "<link rel='stylesheet' href='/stylesheets/all.css'>",
    "<link rel='stylesheet' href='#{assets.fetch('build/stylesheets/all.min.css')}'>" \
    or raise "Couldn't find <link> for /stylesheets/all.min.css"
  index.gsub! "<script src='javascripts/browserified.js'></script>",
    "<script src='#{assets.fetch('build/javascripts/browserified.min.js')}'></script>" \
    or raise "Couldn't find <script> for /javascripts/browserified.min.css"
  index.gsub! "<script src='javascripts/vendor.js'></script>",
    "<script src='#{assets.fetch('build/javascripts/vendor.min.js')}'></script>" \
    or raise "Couldn't find <script> for /javascripts/vendor.min.css"
  File.open(task.name, 'w') { |f| f.write index }
end

task :dist_all => %W[
  dist
  dist/index.html
]

task :serve_dist => :dist_all do
  require 'webrick' # require inside block to save time
  class NonCachingFileHandler < WEBrick::HTTPServlet::FileHandler
    def do_GET request, response
      super
      response['Cache-Control'] = 'no-cache, must-revalidate'
    end
  end
  server = WEBrick::HTTPServer.new BindAddress: '127.0.0.1', Port: 3000,
    AccessLog: [[$stderr, '%t %s %m %U']]
  server.mount '/', NonCachingFileHandler , 'dist'
  trap 'INT' do exit! 1 end
  server.start
end

task :default => :build_all
