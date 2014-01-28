isConstant = require('constantinople')
toConstant = require('constantinople').toConstant

Compiler = (node, options) ->
  compile: ->
    depth = -1
    seenDepth0 = false

    visitTag = (tag) ->
      depth += 1
      if 0 == depth && seenDepth0
        throw new Error('Component may have no more than one root node')
      seenDepth0 = true

      bufferExpression('React.DOM.' + tag.name + '(')
      visitAttributes(tag.attrs, tag.attributeBlocks)
      visitArgs(tag)
      bufferExpression(')')
      depth -= 1

    visitArgs = (node) ->
      len = node.block.nodes.length
      if node.code || len
        bufferExpression(',\n')

      if node.code
        visitCode(node.code)

      for node, i in node.block.nodes
        visit(node)
        if i + 1 < len
          bufferExpression(', ')

    visitBlock = (block) ->
      len = block.nodes.length
      for node, i in block.nodes
        visit(node)
        if i + 1 < len
          bufferExpression(' + \n')

    visitAttributes = (attrs, attributeBlocks) ->
      if attrs && attrs.length
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
          pairs.push(JSON.stringify(name) + ':' + val)

        bufferExpression('{' + pairs.join(',') + '}')

      else
        bufferExpression('null')

    visitCode = (code) ->
      return unless code
      bufferExpression(code.val)

    visitText = (node) ->
      bufferExpression(JSON.stringify(node.val))

    visitNodes =
      Text: visitText
      Tag: visitTag
      Block: visitBlock

    parts = ['function(){']
    bufferExpression = (str) -> parts.push(str)
    visit = (node) -> visitNodes[node.type](node)
    visit(node)

    toPush = (part) -> 'buf.push(' + JSON.stringify(part)+ ');'

    bufferExpression('\n')
    return parts.map(toPush).join('\n')

module.exports = Compiler
