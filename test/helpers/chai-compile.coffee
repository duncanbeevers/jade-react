chai = require('chai')

chai.use (chai, utils) ->
  Assertion = chai.Assertion

  Assertion.addMethod 'transform', (input) ->
    transform = @_obj

    fn = -> transform(input)
    utils.flag(this, 'transform', fn)

  Assertion.addMethod 'into', (output) ->
    transform = utils.flag(this, 'transform')

    actualOutput = transform()
    new Assertion(output).to.equal(actualOutput)
