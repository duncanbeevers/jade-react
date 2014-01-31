UglifyJS = require('uglify-js')
compressor = UglifyJS.Compressor(side_effects: false)

module.exports = (expressionOrAst) ->
  if expressionOrAst instanceof UglifyJS.AST_Node
    ast = expressionOrAst
  else
    ast = UglifyJS.parse(expressionOrAst)

  ast.figure_out_scope()

  # Combine constant strings
  ast = ast.transform(compressor)

  # Trim trailing semi-colon
  expression = ast.print_to_string()
  return expression.slice(0, expression.length - 1)
