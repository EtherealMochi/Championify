gulp = require 'gulp'
async = require 'async'
fs = require 'fs'
coffee = require 'gulp-coffee'
uglify = require 'gulp-uglify'
gutil = require 'gulp-util'
clean = require 'gulp-clean'
fs = require 'fs-extra'
mkdirp = require 'mkdirp'
runSequence = require 'run-sequence'
glob = require 'glob'
exec = require('child_process').exec
nib = require 'nib'
stylus = require 'gulp-stylus'
browserify = require 'browserify'
coffeeify = require 'coffeeify'
source = require 'vinyl-source-stream'
bower = require 'gulp-bower'
preen = require 'preen'
flatten = require 'gulp-flatten'
pkg = require './package.json'

GLOBAL.buildFileName = 'championify'

gulp.task 'bower', ->
  return bower()

gulp.task 'preen', (cb) ->
  preen.preen {}, cb

gulp.task 'bower_copy', ->
  gulp.src('./bower_components/**/*.js')
    .pipe(flatten())
    .pipe gulp.dest('./dev/vendor/js/')

  gulp.src('./bower_components/**/*.map')
    .pipe(flatten())
    .pipe gulp.dest('./dev/vendor/js/')

  gulp.src(['./bower_components/**/*.css', '!./bower_components/iCheck/**'])
    .pipe(flatten())
    .pipe gulp.dest('./dev/vendor/css/')


gulp.task 'mkdir', (cb) ->
  glob './app/**/' , (err, paths) ->
    async.each paths, (path, acb) ->
      path = path.replace('./app', './dev')
      mkdirp path, ->
        acb()
    , ->
      cb()

gulp.task 'symlink', (cb) ->
  glob './app/**', {nodir: true} , (err, paths) ->
    async.each paths, (oldPath, acb) ->
      newPath = oldPath.replace('./app', './dev')
      oldPath = oldPath.replace('./app/', process.cwd()+'/app/')
      fs.symlink oldPath, newPath, (err) ->
        acb null
    , () ->
      cb()

gulp.task 'coffee', ->
  gulp.src(['./atomshell.coffee'], {base: './'})
    .pipe(coffee(bare: true).on('error', gutil.log))
    # .pipe(uglify())
    .pipe gulp.dest('./dev')


gulp.task 'stylus', ->
  gulp.src('./stylesheets/*.styl')
  .pipe(stylus({use: nib(), compress: true}))
  .pipe gulp.dest('./dev/css')


gulp.task 'browserify', (cb) ->
  browserify({
    transform: [coffeeify]
    entries: ['./functions/main.coffee']
    ignore: ['http', 'https']
  })
  .bundle()
  .pipe(source('main.js'))
  .pipe(gulp.dest('./dev/js/'))


gulp.task 'run-watch', (cb) ->
  gulp.watch './stylesheets/*.styl', ['stylus']
  gulp.watch './functions/*.coffee', ['browserify']

  cmd = '../node_modules/.bin/electron .'
  console.log cmd
  exec cmd, {'cwd': './dev'},(err, std, ste) ->
    console.log err if err
    # console.log std
    # console.log ste
    # cb()
    process.exit(0)


# gulp.task 'clean', ->
#   gulp.src(['./app.js', './helpers.js'])
#     .pipe(clean(force: true))
#
# gulp.task 'clean-build', ->
#   gulp.src(['./build'])
#     .pipe(clean(force: true))
#
#
# gulp.task 'coffee', ->
#   gulp.src(['./app.coffee', './helpers.coffee'], {base: './'})
#     .pipe(coffee(bare: true).on('error', gutil.log))
#     .pipe(uglify())
#     .pipe gulp.dest('./')


gulp.task 'dev', ->
  runSequence('mkdir', 'bower_copy', 'symlink', 'coffee', 'stylus', 'browserify', 'run-watch')

gulp.task 'setup', ->
  runSequence('bower', 'preen', 'dev')
