chai = require('chai')

chai.use (chai, utils) ->
  Assertion = chai.Assertion

  Assertion.addMethod 'transform', (input) ->
    transform = @_obj
    new Assertion(-> transform(input))

  Assertion.addMethod 'into', (output) ->
    actualOutput = @_obj()
    new Assertion(output).to.equal(actualOutput)
