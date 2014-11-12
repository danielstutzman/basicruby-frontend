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
      -t istanbulify
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
  | ../../node_modules/uglify-js/bin/uglifyjs -b "ascii-only=true, beautify=false"
  ].join(' ')
  create_with_sh command, "../../#{task.name}"
end

file 'build/stylesheets' => Dir.glob('app/stylesheets/*.*css') do |task|
  sh 'sass --update app/stylesheets:build/stylesheets'
  sh 'sass --update bower_components/pytutor-on-bower/css:build/stylesheets'
  sh 'cp -R bower_components/pytutor-on-bower/css/images/ build/stylesheets/images'
end

file 'bower_components/basicruby-interpreter/dist' do |task|
  sh 'cd bower_components/basicruby-interpreter; bundle install; rake'
end

task :default => %W[
  bower_components/basicruby-interpreter/dist
  build/javascripts/browserified.js
  build/javascripts/browserified.min.js
  build/stylesheets
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
      -t istanbulify
      --insert-global-vars ''
      -d
      -o ../../build/javascripts/browserified.js
      #{paths}
      --verbose
      &
  ].join(' ')
  sh command
end
