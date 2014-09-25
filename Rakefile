def create_with_sh(command, path)
  begin
    sh "#{command} > #{path}"
  rescue
    sh "rm -f #{path}"
    raise
  end
end

if defined?(before)
  before 'assets:precompile' do
    Rake::Task['js'].invoke
  end
end

file 'build/javascripts/browserified.js' => Dir.glob('app/*.coffee') do |task|
  mkdir_p 'build/javascripts'

  sh 'coffee -bc -o build/coffee/app app'

  paths = task.prerequisites.map { |path|
    path.gsub(%r[^app/(.*)\.coffee$], 'app/\1.js')
  }.join(' ')
  command = %W[
    cd build/coffee &&
    ../../node_modules/.bin/browserify
      --insert-global-vars ''
      -d
      #{paths}
  ].join(' ')
  create_with_sh command, "../../#{task.name}"
end

file 'build/javascripts/browserified.min.js' => Dir.glob('app/*.coffee') do |task|
  mkdir_p 'build/javascripts'

  sh 'coffee -bc -o build/coffee/app app'

  paths = task.prerequisites.map { |path|
    path.gsub(%r[^app/(.*)\.coffee$], 'app/\1.js')
  }.join(' ')
  command = %W[
    cd build/coffee &&
    ../../node_modules/.bin/browserify
      --insert-global-vars ''
      #{paths}
  | ../../node_modules/uglify-js/bin/uglifyjs -b ascii-only=true
  ].join(' ')
  create_with_sh command, "../../#{task.name}"
end

file 'build/javascripts/browserified-coverage.js' =>
    Dir.glob(['app/*.coffee', 'test/*.coffee']) do |task|
  mkdir_p 'build/javascripts'
  sh 'coffee -bc -o build/coffee/app app'

  paths = task.prerequisites.map { |path|
    path.gsub %r[\.coffee$], '.js'
  }.join(' ')
  command = %W[
     coffee -c -o build/coffee/test test
  && cd build/coffee
  && ../../node_modules/.bin/istanbul
       instrument .
       --no-compact --embed-source --preserve-comments
       -o ../../build/istanbul
  && cd ../../build/istanbul
  && ../../node_modules/.bin/browserify
       --insert-global-vars ''
       -d
      #{paths}
  ].join(' ')
  create_with_sh command, "../../#{task.name}"

  puts "To run tests: python -m SimpleHTTPServer; cd test; node cov_server.js;
    open http://localhost:8000/test/index.html?coverage=true"
end

file 'build/stylesheets' => Dir.glob('app/stylesheets/*.*css') do |task|
  sh 'sass --update app/stylesheets:build/stylesheets'
end

task :default => %W[
  build/javascripts/browserified.js
  build/javascripts/browserified.min.js
  build/stylesheets
  build/javascripts/browserified-coverage.js
]

task :watch do
  sh 'sass --watch app/stylesheets:build/stylesheets &'

  sh 'coffee -bcw -o build/coffee/app app &'

  sleep 1 # give time for coffee to run
  paths = Dir.glob('app/*.coffee').map { |path|
    path.gsub! /\.coffee$/, '.js'
  }.join(' ')
  command = %W[
    cd build/coffee &&
    ../../node_modules/.bin/watchify
      #{ENV['RAILS_ENV'] == 'assets' ? '-t uglifyify' : ''}
      --insert-global-vars ''
      -d
      -o ../../build/javascripts/browserified.js
      #{paths}
      --verbose
      &
  ].join(' ')
  sh command
end
