chai = require('chai')

chai.use (chai, utils) ->
  Assertion = chai.Assertion

  Assertion.addMethod 'transform', (input) ->
    transform = @_obj
    new Assertion(-> transform(input))

  Assertion.addMethod 'into', (expectedOutput) ->
    actualOutput = @_obj()
    new Assertion(actualOutput).to.equal(expectedOutput)
