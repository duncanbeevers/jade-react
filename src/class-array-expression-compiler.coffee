UglifyJS = require('uglify-js')
expressionCompiler = require('./class-expression-compiler')

# Insert a space string node between each extant pair of nodes
# in the array.
mingleSpaces = (previous, element, index) ->
  if previous.length
    previous.push new UglifyJS.AST_String(value: ' ')
  previous.push element
  return previous

# Transforms an uglify AST representing a single Array
# into an AST representing a series of concatenation/addition
# operations suitable for css class names.
#
#     ['a', 'b', 'c']
#
#     'a'+' '+'b'+' '+'c'
#
uglifyArrayToStringConcatTransform = do ->
  newBody = undefined
  constructBinaryAdditions = (elements) ->
    right = elements[elements.length - 1]
    if elements.length > 2
      left = constructBinaryAdditions(elements.slice(0, elements.length - 1))
    else
      left = elements[0]

    return new UglifyJS.AST_Binary
      left: left
      operator: '+'
      right: right

  before = (node, descend) ->
    if node instanceof UglifyJS.AST_Array
      elements = node.elements.reduce mingleSpaces, []
      newBody = constructBinaryAdditions(elements)
      return newBody

    descend(node, this)
    return node

  new UglifyJS.TreeTransformer(before)

module.exports = (expression) ->
  ast = UglifyJS.parse(expression)
  ast = ast.transform(uglifyArrayToStringConcatTransform)

  return expressionCompiler(ast)
