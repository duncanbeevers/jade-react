chai = require('chai')
expect = chai.expect

# Load custom assertions
require('./helpers/chai-compile')

render = require('../src/main')

describe 'compile', ->
  fs = require('fs')

  setupFixtureTests = (pretty) ->
    fixturesDir = 'test/fixtures/'
    fixtures = fs.readdirSync(fixturesDir)
    inputs = fixtures.filter (fixture) -> /\.jade$/.test(fixture)

    for inputFileName in inputs
      if pretty
        suffix = '.pretty.js'
      else
        suffix = '.js'

      outputFileName = inputFileName + suffix

      do (inputFileName, outputFileName) ->
        try
          markup = String(fs.readFileSync(fixturesDir + inputFileName))
          output = String(fs.readFileSync(fixturesDir + outputFileName))

          it 'compiles ' + inputFileName + ' to ' + outputFileName, ->
            options = pretty: pretty
            expect(render).to.transform(markup, options).into(output)
        catch setupError
          it 'failed to setup fixture test for file pair ' + inputFileName + '→' + outputFileName, ->
            expect(-> throw setupError).not.to.throw()

  setupFixtureTests(false)
  setupFixtureTests(true)

  it 'should not compile multiple root nodes', ->
    expect(render).transform('p\np\n').to.throw('Component may have no more than one root node')

  it 'should not compile doctype', ->
    expect(render).transform('doctype html').to.throw('Component may not have doctype tag')
