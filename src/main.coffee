jade = require('jade')
compiler = require('./compiler')

module.exports = (markup) ->
  jade.render(markup, compiler: compiler)
