isConstant = require('constantinople')
toConstant = require('constantinople').toConstant

pairSort = (a, b) ->
  if a[0] < b[0]
    -1
  else if a[0] > b[0]
    1
  else
    0

Compiler = (node, options) ->
  pretty = options.pretty
  if pretty
    prettyComma = ', '

  compile: ->
    visitTag = (tag) ->
      if pretty
        bufferExpression(indentToDepth())
        bufferExpression('React.DOM.' + tag.name + '(')
      else
        bufferExpression('React.DOM.' + tag.name + '(')

      visitAttributes(tag.attrs, tag.attributeBlocks)

      depth += 1
      if 0 == depth && seenDepth0
        throw new Error('Component may have no more than one root node')
      seenDepth0 = true
      anyArgs = visitArgs(tag)
      depth -= 1

      if pretty
        if anyArgs
          bufferExpression('\n' + indentToDepth() + ')')
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

    visitAttributes = (attrs, attributeBlocks) ->
      unless attrs && attrs.length
        bufferExpression('null')
        return

      visited = {}
      gatheredClassNames = []
      normalized = {}

      for attr in attrs
        name = attr.name
        val = attr.val

        if 'class' == name
          name = 'className'

        if 'className' != name && visited[name]
          throw new Error('Duplicate key ' + JSON.stringify(name) + ' is not allowed.')
        visited[name] = true

        if 'className' == name
          gatheredClassNames.push val
        else
          normalized[name] = val

      if visited['className']
        constantClassNames = []
        dynamicClassNames = []
        for className in gatheredClassNames
          if isConstant(className)
            constantClassNames.push toConstant(className)
          else
            dynamicClassNames.push className

        classNames = []
        if constantClassNames.length
          classNames.push JSON.stringify(constantClassNames.join(' '))

        normalized['className'] = classNames.concat(dynamicClassNames).join(' + " " + ')

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
        depth += 1
        bufferExpression('\n' + indentToDepth())
        bufferExpression(pairs.join(',\n' + indentToDepth()))
        depth -= 1
        bufferExpression('\n' + indentToDepth())
      else
        bufferExpression(pairs.join(','))
      bufferExpression('}')

    visitCode = (code) ->
      return unless code
      if pretty
        bufferExpression(indentToDepth() + code.val)
      else
        bufferExpression(code.val)

    visitText = (node) ->
      if pretty
        bufferExpression(indentToDepth() + JSON.stringify(node.val))
      else
        bufferExpression(JSON.stringify(node.val))

    visitNodes =
      Text: visitText
      Tag: visitTag
      Block: visitBlock

    # Setup
    depth = -1
    seenDepth0 = false

    indentToDepth = () ->
      # depth 1 is implicit in function wrapper
      if parts.length > 1
        Array(depth + 3).join('  ')
      else
        ''

    # Open render function body
    if pretty
      parts = ['function () {\n  return ']
    else
      parts = ['function(){return ']

    bufferExpression = (str) -> parts.push(str)
    visit = (node) -> visitNodes[node.type](node)
    visit(node)

    # Close function wrapper.
    if pretty
      bufferExpression(';\n}\n')
    else
      bufferExpression(';}')

    # Map to jade machine instruction statements;
    toPush = (part) -> 'buf.push(' + JSON.stringify(part)+ ');'
    console.log(parts.join(''))
    return parts.map(toPush).join('\n')

module.exports = Compiler
