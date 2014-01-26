jade = require('jade')
compiler = require('./compiler')

module.exports = (markup) ->
  String(jade.render(markup, compiler: compiler))
