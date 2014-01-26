gulp  = require('gulp')
mocha = require('gulp-mocha')

gulp.task 'test', ->
  gulp.src(['test/*.coffee'], read: false)
    .pipe(mocha(reporter: 'spec'))

gulp.task 'default', ['test']
