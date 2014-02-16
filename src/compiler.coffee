React = require('react')

isString = (s) -> '\'' == s[0] || '"' == s[0]
toString = (s) -> s.slice(1, s.length - 1)

arrayCompiler = require('./class-array-expression-compiler')
expressionCompiler = require('./class-expression-compiler')

prettyMap = '  ' + """
  function map (obj, fn) {
    if ('number' === typeof obj.length) return obj.map(fn);
    var result = [], key, hasProp = {}.hasOwnProperty;
    for (key in obj) hasProp.call(obj, key) && result.push(fn(key, obj[key]));
    return result;
  }
  """.split('\n').join('\n  ') + '\n\n'

terseMap = """
  function map(o,f){if('number'===typeof o.length)return o.map(f);var r=[],k,h={}.hasOwnProperty;for(k in o)h.call(o,k)&&r.push(f(k,o[k]));return r;}
  """

pairSort = (a, b) ->
  if a[0] < b[0]
    -1
  else if a[0] > b[0]
    1
  else
    0

partition = (collection, fn) ->
  left = []
  right = []
  for item in collection
    if fn(item)
      left.push item
    else
      right.push item
  [left, right]

isArrayExpression = (expression) ->
  '[' == expression[0] && ']' == expression[expression.length - 1]

joinArrays = (expression) ->
  if isArrayExpression(expression)
    expression + '.join(" ")'
  else
    expression

Compiler = (node, options) ->
  compile: ->
    # Setup
    pretty            = options.pretty
    depth             = -1
    seenDepth0        = false
    parts             = []
    seenDepth0        = false
    needsMap          = false
    continueIndenting = false

    visitTag = (tag) ->
      bufferExpression(indentToDepth())
      if React.DOM[tag.name]
        bufferExpression('React.DOM.')
      bufferExpression(tag.name, '(')

      visitAttributes(tag.attrs, tag.attributeBlocks)

      depth += 1
      if 0 == depth && seenDepth0
        throw new Error('Component may have no more than one root node')
      seenDepth0 = true
      anyArgs = visitArgs(tag)
      depth -= 1

      if pretty
        if anyArgs
          bufferExpression('\n', indentToDepth(), ')')
        else
          bufferExpression(')')
      else
        bufferExpression(')')

    visitArgs = (node) ->
      len = node.block.nodes.length
      anyArgs = node.code || len
      if anyArgs
        if pretty
          bufferExpression(',\n')
        else
          bufferExpression(',')

      if node.code
        visitCode(node.code)

      for node, i in node.block.nodes

        visit(node)

        if i + 1 < len
          if pretty
            bufferExpression(',\n')
          else
            bufferExpression(',')

      return anyArgs

    visitBlock = (block) ->
      len = block.nodes.length
      for node, i in block.nodes
        visit(node)
        if i + 1 < len
          bufferExpression(' + \n')

    normalizeClassExpressions = (expressions) ->
      # If the expression is an array, we won't peer inside,
      # and we'll just invoke a join function on the whole expression.
      [arrayExpressions, expressions] = partition expressions,
        isArrayExpression

      [stringExpressions, expressions] = partition expressions,
        isString

      stringClassNames = stringExpressions.map(toString)
      stringClassNamesExpression = JSON.stringify(stringClassNames.join(' '))

      if stringClassNames.length
        expressions.unshift(stringClassNamesExpression)

      if arrayExpressions.length
        for expression in arrayExpressions
          expressions.push(arrayCompiler(expression))

      if 1 == expressions.length
        expression = expressions[0]
      else
        expression = expressionCompiler(expressions.join('+" "+'))

      return expression

    normalizeAttributes = (attrs) ->
      visited = {}
      classExpressions = []
      normalized = {}

      for attr in attrs
        name = attr.name
        val = attr.val

        # `class` attributes are automatically treated as `className`
        if 'class' == name
          name = 'className'

        # Only `class`/`className` attributes are extensible.
        # Every other attribute blows up if its seen twice in a tag
        if 'className' != name && visited[name]
          throw new Error('Duplicate key ' + JSON.stringify(name) + ' is not allowed.')
        visited[name] = true

        # `className` is handled specially.
        # First, at compile time, constant class names are
        # gathered and concatenated, like so `foo baz`
        # Then dynamic components are added as run-time expressions,
        # concatenating themselves on to the constant component.
        if 'className' == name
          classExpressions.push val
        else
          normalized[name] = val

      # If we ever visited a `className` attribute, we need to
      # build its normalized value manually.
      if visited['className']
        normalized['className'] = normalizeClassExpressions(classExpressions)

      return normalized

    visitAttributes = (attrs, attributeBlocks) ->
      unless attrs && attrs.length
        bufferExpression('null')
        return

      normalized = normalizeAttributes(attrs)

      pairs = []
      for name, val of normalized
        pairs.push([name, val])

      # Lexically sort by attribute name
      pairs.sort(pairSort)

      if pretty
          sep = ': '
        else
          sep = ':'
      pairs = pairs.map (pair) ->
        [name, val] = pair
        JSON.stringify(name) + sep + val

      bufferExpression('{')
      if pretty
        depth += 2
        bufferExpression('\n', indentToDepth())
        bufferExpression(pairs.join(',\n' + indentToDepth()))
        depth -= 1
        bufferExpression('\n', indentToDepth())
        depth -= 1
      else
        bufferExpression(pairs.join(','))
      bufferExpression('}')

    visitCode = (code) ->
      return unless code
      bufferExpression(indentToDepth(), code.val)

    visitText = (node) ->
      bufferExpression(indentToDepth(), JSON.stringify(node.val))

    visitEach = (node) ->
      needsMap = true
      depth += 1
      bufferExpression(indentToDepth(), 'map(', node.obj)

      if pretty
        bufferExpression(', function (')
      else
        bufferExpression(',function(')
      bufferExpression(node.val)

      if pretty
        bufferExpression(', ')
      else
        bufferExpression(',')

      bufferExpression(node.key, ')')

      if pretty
        bufferExpression(' {\n')
      else
        bufferExpression('{')

      depth += 1
      bufferExpression(indentToDepth(), 'return ')
      continueIndenting = false
      for node in node.block.nodes
        visit(node)

      if pretty
        bufferExpression(';\n')
      else
        bufferExpression(';')

      depth -= 1
      if pretty
        bufferExpression(indentToDepth(), '}\n')
      else
        bufferExpression(indentToDepth(), '}')
      depth -= 1
      bufferExpression(indentToDepth(), ')')

    visitNodes =
      Text: visitText
      Tag: visitTag
      Block: visitBlock
      Each: visitEach
      Code: visitCode
      Doctype: -> throw new Error('Component may not have doctype tag')

    indentToDepth = ->
      return '' unless pretty
      if continueIndenting
        # depth 1 is implicit in function wrapper
        Array(depth + 3).join('  ')
      else
        continueIndenting = true
        ''

    # Open render function body
    bufferExpression = (strs...) -> parts = parts.concat(strs)
    visit = (node) -> visitNodes[node.type](node)
    visit(node)

    # Create the function wrapper.
    if pretty
      parts.unshift '  return '
      if needsMap
        parts.unshift prettyMap
      parts.unshift 'function () {\n'
    else
      parts.unshift 'return '
      if needsMap
        parts.unshift terseMap
      parts.unshift 'function(){'

    if pretty
      bufferExpression(';\n}\n')
    else
      bufferExpression(';}')

    # Map to jade machine instruction statements;
    toPush = (part) -> 'buf.push(' + JSON.stringify(part)+ ');'
    return parts.map(toPush).join('\n')

module.exports = Compiler
