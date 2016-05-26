require 'json'
require 'net/http'
require 'webrick'

def create_with_sh command, path
  begin
    sh "#{command} > #{path}"
  rescue
    sh "rm -f #{path}"
    raise
  end
end

class NonCachingFileHandler < WEBrick::HTTPServlet::FileHandler
  def do_GET request, response
    super
    if request.path == '/'
      # no-store because If-Modified-Since won't distinguish between build and dist index.html
      response['Cache-Control'] = 'no-store'
    elsif request.path.match /\.[0-9a-f]{5}\.(png|jpg|jpeg|css|js)$/
      response['Cache-Control'] = 'max-age=31556926'
    else
      response['Cache-Control'] = 'no-cache, must-revalidate'
    end
  end
end

def run_forwarding_web_server on_port, static_dir, api_hostname, api_port
  server = WEBrick::HTTPServer.new BindAddress: '127.0.0.1', Port: on_port,
    AccessLog: [[$stderr, '%t %s %m %U']]
  server.mount '/', NonCachingFileHandler, static_dir
  server.mount_proc '/api' do |request, response|
    http = Net::HTTP.new api_hostname, api_port
    if request.request_method == 'GET'
      method = Net::HTTP::Get.new response.request_uri.path
    elsif request.request_method == 'POST'
      method = Net::HTTP::Post.new response.request_uri.path
      method.body = request.body
    end
    request.each { |key, value| method.add_field key, value } # copy headers
    response2 = http.request method

    response['X-Forwarded-From'] =
      "http://#{api_hostname}:#{api_port}#{response.request_uri.path}"
    response.status = response2.code
    response.body = response2.body
  end
  trap 'INT' do exit! 1 end
  server.start
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
    sh "cat node_modules/react/dist/react.js >> #{task.name}"
    sh "cat node_modules/underscore/underscore.js >> #{task.name}"
    sh "echo >> #{task.name}" # needs a newline if anything follows
    sh "cat node_modules/opal/dist/opal.js >> #{task.name}"
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
    -v -o #{task.name}", task.name
end

desc 'Compile app/*.coffee to build/javascripts/browserified.js incrementally with inline source'
task :watch_coffee => %w[build/javascripts] do
  sh "node_modules/watchify/bin/cmd.js \
    -t coffeeify app/application.coffee -d --extension=.coffee \
    -x react -x react-dom -x underscore -x bluebird -x react-addons-update -x redux -x opal \
    -v -o build/javascripts/browserified.js"
end

file 'build/stylesheets/all.css' => %w[build/stylesheets] do |task|
  sh "sass --update app/stylesheets:build/stylesheets --sourcemap=none"
  create_with_sh "cat build/stylesheets/*.css node_modules/codemirror/lib/codemirror.css",
    task.name
end

task :serve_build => :build_all do
  run_forwarding_web_server 3000, 'build', 'localhost', 9292
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

  assets = JSON.load(File.read('dist/assets.json'))
  assets.each { |key, value| sh "gzip -9 -k #{value}" }
end

file 'dist/index.html' => %w[app/index.html dist/assets.json] do |task|
  sh 'rm -f dist/index.html.gz' # delete old gz in case this fails

  assets = JSON.load(File.read('dist/assets.json'))
  assets.each { |key, value| value.gsub! 'dist/', '/' }

  index = File.read('app/index.html')
  index.gsub! "<link rel='stylesheet' href='/stylesheets/all.css'>",
    "<link rel='stylesheet' href='#{assets.fetch('build/stylesheets/all.min.css')}'>" \
    or raise "Couldn't find <link> for /stylesheets/all.min.css"
  index.gsub! "<script src='/javascripts/browserified.js'></script>",
    "<script src='#{assets.fetch('build/javascripts/browserified.min.js')}'></script>" \
    or raise "Couldn't find <script> for /javascripts/browserified.min.css"
  index.gsub! "<script src='/javascripts/vendor.js'></script>",
    "<script src='#{assets.fetch('build/javascripts/vendor.min.js')}'></script>" \
    or raise "Couldn't find <script> for /javascripts/vendor.min.css"
  File.open(task.name, 'w') { |f| f.write index }
end

file 'dist/index.html.gz' => 'dist/index.html' do
  sh 'gzip -9 -k dist/index.html'
end

task :dist_all => %W[
  dist
  dist/index.html
  dist/index.html.gz
]

task :serve_dist => :dist_all do
  run_forwarding_web_server 3000, 'dist', 'localhost', 9292
end

task :deploy_dist_to_digitalocean => :dist_all do
  sh %q[INSTANCE_IP=`tugboat droplets | grep 'basicruby ' | egrep -oh "[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+" || true`
    echo INSTANCE_IP=$INSTANCE_IP
    rsync -rv \
      -e "ssh -l deployer -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null" \
      dist/ root@$INSTANCE_IP:/home/deployer/basicruby/current/public \
      --exclude vendor --exclude ".*" --exclude tmp --exclude log \
      --delete
  ]
  sh "tugboat ssh -n basicruby -c 'chown -R deployer:www-data /home/deployer/basicruby/current'"
end

task :default => :build_all
