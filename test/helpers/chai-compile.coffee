chai = require('chai')

chai.use (chai, utils) ->
  Assertion = chai.Assertion

  Assertion.addMethod 'transform', (args...) ->
    transform = @_obj
    new Assertion(-> transform.apply(this, args))

  Assertion.addMethod 'into', (expectedOutput) ->
    actualOutput = @_obj()
    new Assertion(actualOutput).to.equal(expectedOutput)
