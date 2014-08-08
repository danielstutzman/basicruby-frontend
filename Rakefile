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

file 'build/browserified.js' => Dir.glob('app/*.coffee') do |task|
  mkdir_p 'build'
  dash_r_paths = task.prerequisites.map { |path|
    ['-r', "./#{path}"]
  }.flatten.join(' ')
  command = %W[
    node_modules/.bin/browserify
      -t coffeeify
      #{ENV['RAILS_ENV'] == 'assets' ? '-t uglifyify' : ''}
      --insert-global-vars ''
      -d
      #{dash_r_paths}
  ].join(' ')
  create_with_sh command, task.name
end

file 'test/browserified-coverage.js' =>
  Dir.glob(['app/*.coffee', 'test/*.coffee']) do |task|
  dash_r_paths = task.prerequisites.map { |path|
    if path.start_with?('app/')
      path = path.gsub(%r[^app/], 'app-istanbul/')
      path = path.gsub(%r[\.coffee$], '.js')
      ['-r', "./#{path}"]
    end
  }.compact.flatten.join(' ')
  non_dash_r_paths = task.prerequisites.select { |path|
    path.start_with?('test/')
  }.join(' ')
  command = %W[
     rm -rf app-compiled app-istanbul
  && cp -R app app-compiled
  && node_modules/coffeeify/node_modules/coffee-script/bin/coffee
     -c app-compiled/*.coffee
  && rm app-compiled/*.coffee
  && perl -pi -w -e 's/\.coffee/\.js/g;' app-compiled/*.js
  && node_modules/.bin/istanbul
       instrument app-compiled
       --no-compact --embed-source --preserve-comments
       -o app-istanbul
  && node_modules/.bin/browserify
     --insert-global-vars '' -t coffeeify -d
    #{dash_r_paths}
    #{non_dash_r_paths}
  ].join(' ')
  create_with_sh command, task.name

  command = %W[rm -rf app-compiled app-istanbul].join(' ')
  sh command

  puts "To run tests: python -m SimpleHTTPServer; cd test; node cov_server.js;
    open http://localhost:8000/test/index.html?coverage=true"
end

file 'build/stylesheets/app.css' => Dir.glob('app/stylesheets/*.*css') do |task|
  mkdir_p 'build/stylesheets'
  command = %W[
    cat #{task.prerequisites.join(' ')} | sass --scss
  ].join(' ')
  create_with_sh command, task.name
end

task :default => %W[
  build/browserified.js
  build/stylesheets/app.css
  test/browserified-coverage.js
]
