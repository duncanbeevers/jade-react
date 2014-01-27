chai = require('chai')
expect = chai.expect

# Load custom assertions
require('./helpers/chai-compile')

render = require('../src/main')

describe 'compile', ->
  fs = require('fs')

  setupFixtureTests = ->
    fixturesDir = 'test/fixtures/'
    fixtures = fs.readdirSync(fixturesDir)
    inputs = fixtures.filter (fixture) -> /\.jade$/.test(fixture)

    for inputFileName in inputs
      outputFileName = inputFileName + '.js'

      do (inputFileName, outputFileName) ->
        markup = String(fs.readFileSync(fixturesDir + inputFileName))
        output = String(fs.readFileSync(fixturesDir + outputFileName))

        it 'compiles ' + inputFileName + ' to ' + outputFileName, ->
          expect(render).to.transform(markup).into(output)

  try
    setupFixtureTests()
  catch setupError
    it 'should not have failed to setup fixture tests', ->
      expect(-> throw setupError).not.to.throw()

  it 'should not compile multiple root nodes', ->
    expect(render).transform('p\np\n').to.throw()
