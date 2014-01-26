chai = require('chai')
expect = chai.expect

# Load custom assertions
require('./helpers/chai-compile')

render = require('../src/main')

describe 'compile', ->
  fs = require('fs')

  fixturesDir = 'test/fixtures/'
  fixtures = fs.readdirSync(fixturesDir)
  console.log JSON.stringify(fixtures)
  inputs = fixtures.filter (fixture) -> /\.jade$/.test(fixture)

  for inputFileName in inputs
    outputFileName = inputFileName + '.js'

    do (inputFileName, outputFileName) ->
      markup = String(fs.readFileSync(fixturesDir + inputFileName))
      output = String(fs.readFileSync(fixturesDir + outputFileName))

      it 'compiles ' + inputFileName + ' to ' + outputFileName, ->
        # expect(render).to.transform(markup)
        expect(render).to.transform(markup).into(output)
