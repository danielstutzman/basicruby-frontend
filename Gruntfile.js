module.exports = function(grunt) {

  grunt.loadNpmTasks('grunt-contrib-clean');
  grunt.loadNpmTasks('grunt-contrib-concat');
  grunt.loadNpmTasks('grunt-contrib-copy');
  grunt.loadNpmTasks('grunt-contrib-cssmin');
  grunt.loadNpmTasks('grunt-contrib-imagemin');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-rev');
  grunt.loadNpmTasks('grunt-smartrev');
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
      // Note: make sure to update app/index if there are any changes
      vendor: {
        src: [
          'bower_components/react/react.min.js',
          'bower_components/underscore/underscore.min.js',
          'bower_components/codemirror/lib/codemirror.min.js',
          'bower_components/codemirror/mode/ruby/ruby.min.js',
          'bower_components/easyxdm/easyXDM.min.js',
          'bower_components/history.js/scripts/bundled/html4+html5/native.history.js',
        ],
        dest: 'dist/javascripts/vendor.min.js',
      },
      pytutor: {
        src: [
          'bower_components/pytutor-on-bower/js/*.js',
        ],
        dest: 'dist/javascripts/pytutor.js',
      },
    },
    cssmin: {
      combine: {
        files: {
          // Note: make sure to update app/index if there are any changes
          'dist/stylesheets/all.css': [
            'build/stylesheets/*.css',
            'bower_components/codemirror/lib/codemirror.css',
            'build/stylesheets/tutor/*.css',
            'build/stylesheets/pytutor.css',
            'build/stylesheets/ui-lightness.css',
          ],
        }
      }
    },
    uglify: {
      bower_min: {
        options: {
          ASCIIOnly: true, // fixes codemirror bug at https://groups.google.com/forum/#!topic/codemirror/OgTL-Enm3QI
        },
        files: {
          'bower_components/underscore/underscore.min.js': ['bower_components/underscore/underscore.js'],
          'bower_components/codemirror/lib/codemirror.min.js': ['bower_components/codemirror/lib/codemirror.js'],
          'bower_components/codemirror/mode/ruby/ruby.min.js': ['bower_components/codemirror/mode/ruby/ruby.js'],
        },
      },
      basicruby: {
        options: {
          sourceMap: false,
          sourceMapIncludeSources: false,
        },
        files: {
          'dist/javascripts/basicruby.min.js': [
            'bower_components/basicruby-interpreter/dist/opal.js',
            'bower_components/basicruby-interpreter/dist/basicruby-interpreter.js',
          ],
        },
      },
    },
    imagemin: {
      options: {
        optimizationLevel: 3,
        //use: [mozjpeg()],
      },
      appImages: {
        files: [{
          expand: true,
          cwd: 'app/images/',
          src: ['**/*.{png,jpg,gif}'],
          dest: 'dist/images',
        }],
      },
      pytutorImages: {
        files: [{
          expand: true,
          cwd: 'bower_components/pytutor-on-bower/css/images',
          src: ['**/*.{png,jpg,gif}'],
          dest: 'dist/stylesheets/images',
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
        baseUrl: '..',
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
    'concat',
    'imagemin',
    'smartrev'
  ]);
};
