jade = require('jade')
compiler = require('./compiler')

module.exports = (markup, options = {}) ->
  options.compiler = compiler
  jade.render(markup, options)
