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

#file 'build/javascripts/browserified.min.js' => Dir.glob('app/*.coffee') do |task|
#  mkdir_p 'build/javascripts'
#
#  sh 'coffee -bc -o build/coffee/app app'
#
#  paths = task.prerequisites.map { |path|
#    path.gsub(%r[^app/(.*)\.coffee$], 'app/\1.js')
#  }.join(' ')
#  command = %W[
#    cd build/coffee &&
#    ../../node_modules/.bin/browserify
#      --insert-global-vars ''
#      #{paths}
#  | ../../node_modules/uglify-js/bin/uglifyjs -b "ascii-only=true, beautify=false"
#  ].join(' ')
#  create_with_sh command, "../../#{task.name}"
#end

task :build_all => %W[
  build
  build/index.html
  build/images
  build/stylesheets/all.css
  build/javascripts/browserified.js
  build/javascripts/vendor.js
]

task :default => :build_all
