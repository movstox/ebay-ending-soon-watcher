var gulp = require('gulp');
var babel = require('gulp-babel');
var coffee = require('gulp-coffee');
var uglify = require('gulp-uglify');
var nodemon = require('gulp-nodemon');
var concat = require('gulp-concat');
var del = require('del');
var mocha = require('gulp-mocha');

var paths = {
  scripts: ['src/**/*.coffee'],
  tests: ['test/**/*.coffee', 'test/**/*.js']
};

CoffeeScript = require('coffee-script')
CoffeeScript.register()

// Not all tasks need to use streams
// A gulpfile is just another node program and you can use any package available on npm
gulp.task('clean', function() {
  // You can use multiple globbing patterns as you would with `gulp.src`
  return del(['build']);
});

gulp.task('scripts', ['clean', 'test'], function() {
  // Minify and copy all JavaScript (except vendor scripts)
  // with sourcemaps all the way down
  return gulp.src('src/**/*.coffee')
    .pipe(coffee()).pipe(uglify()).pipe(babel({presets: ['es2015']})).pipe(concat('app.min.js')).pipe(gulp.dest('dist'));
});

gulp.task('test', function() {
  return gulp.src('test/test.js', {read: false})
  // gulp-mocha needs filepaths so you can't have any plugins before it
    .pipe(mocha({reporter: 'nyan'}));
});

gulp.task('start', function() {
  var stream = nodemon({
    script: 'dist/app.min.js',
    ext: 'coffee js html',
    env: {
      'NODE_ENV': 'development'
    }
  })
});
// Rerun the task when a file changes
gulp.task('watch', function() {
  gulp.watch(paths.scripts, ['test', 'scripts']);
  gulp.watch(paths.tests, ['test']);
});
// The default task (called when you run `gulp` from cli)
gulp.task('default', ['scripts', 'test', 'start', 'watch']);
