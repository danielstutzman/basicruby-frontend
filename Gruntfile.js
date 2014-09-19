module.exports = function(grunt) {

  grunt.loadNpmTasks('grunt-contrib-clean');
  grunt.loadNpmTasks('grunt-contrib-concat');
  grunt.loadNpmTasks('grunt-contrib-copy');
  grunt.loadNpmTasks('grunt-contrib-cssmin');
  grunt.loadNpmTasks('grunt-contrib-imagemin');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-smartrev');
  grunt.loadNpmTasks('grunt-rev');
  grunt.loadNpmTasks('grunt-usemin');

  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    clean: ['dist'],
    copy: {
      html: {
        src: 'app/index.html',
        dest: 'dist/index.html',
      },
      browserified: {
        src: 'build/javascripts/browserified.min.js',
        dest: 'dist/javascripts/browserified.min.js',
      },
      browserified_map: {
        src: 'build/javascripts/browserified.min.js.map',
        dest: 'dist/javascripts/browserified.min.js.map',
      },
    },
    useminPrepare: {
      options: {
        dest: 'dist',
      },
      html: 'index.html',
    },
    concat: {
      options: {
        separator: ';',
      },
      vendor: {
        src: [
          'bower_components/react/react.min.js',
          'bower_components/underscore/underscore.min.js',
          'bower_components/codemirror/lib/codemirror.min.js',
          'bower_components/codemirror/mode/ruby/ruby.min.js',
          'bower_components/js-signals/dist/signals.min.js',
          'bower_components/hasher/dist/js/hasher.min.js',
          'bower_components/easyxdm/easyXDM.min.js',
        ],
        dest: 'dist/javascripts/vendor.min.js',
      },
    },
    cssmin: {
      combine: {
        files: {
          'dist/stylesheets/all.css': ['build/stylesheets/*.css'],
          'dist/stylesheets/tutor/tutor.css': ['build/stylesheets/tutor/*.css'],
        }
      }
    },
    uglify: {
      bower_min: {
        files: {
          'bower_components/underscore/underscore.min.js': ['bower_components/underscore/underscore.js'],
          'bower_components/codemirror/lib/codemirror.min.js': ['bower_components/codemirror/lib/codemirror.js'],
          'bower_components/codemirror/mode/ruby/ruby.min.js': ['bower_components/codemirror/mode/ruby/ruby.js'],
        },
      },
      basicruby: {
        options: {
          sourceMap: true,
          sourceMapIncludeSources: true,
        },
        files: {
          'dist/javascripts/basicruby.min.js': [
            'bower_components/basicruby-interpreter/dist/opal.js',
            'bower_components/basicruby-interpreter/dist/basicruby-interpreter.js',
            'build/javascripts/browserified.min.js',
          ],
        },
      },
    },
    imagemin: {
      options: {
        optimizationLevel: 3,
        //use: [mozjpeg()],
      },
      dynamic: {
        files: [{
          expand: true,
          cwd: 'app/images/',
          src: ['**/*.{png,jpg,gif}'],
          dest: 'dist/images',
        }],
      },
    },
    rev: {
      options: {
        encoding: 'utf8',
        algorithm: 'md5',
        length: 5,
      },
      files: {
        src: [
          'dist/javascripts/vendor.js',
          'dist/javascripts/basicruby.js',
          'dist/stylesheets/all.css',
          'dist/images/**/*.{jpg,jpeg,gif,png}',
        ]
      }
    },
    usemin: {
      options: {
        assetsDirs: ['dist']
      },
      html: 'dist/index.html',
    },
    smartrev: {
      options: {
        cwd: 'dist',
        noRename: ['index.html'],
      },
      dist: {
        src: ['**/*.{css,jpg,jpeg,gif,png,js,html}'],
        dest: 'stats.json',
      },
    },
  });

  grunt.registerTask('default', ['uglify']);

  grunt.registerTask('default', [
    'clean',
    'copy',
    'useminPrepare',
    'usemin',
    'cssmin',
    'uglify',
    'concat:vendor',
    'imagemin:dynamic',
    'smartrev'
  ]);
};
