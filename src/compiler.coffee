isConstant = require('constantinople')
toConstant = require('constantinople').toConstant

Compiler = (node, options) ->
  compile: ->
    visitTag = (tag) ->
      buffer('React.DOM.' + tag.name + '(')
      visitAttributes(tag.attrs, tag.attributeBlocks)
      visitArgs(tag)
      buffer(')')

    visitArgs = (node) ->
      len = node.block.nodes.length
      if node.code || len
        buffer(', ')

      if node.code
        visitCode(node.code)

      for node, i in node.block.nodes
        visit(node)
        if i + 1 < len
          buffer(' + ')

    visitBlock = (block) ->
      len = block.nodes.length
      for node, i in block.nodes
        visit(node)
        if i + 1 < len
          buffer(' + \n')

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

        buffer('{' + pairs.join(',') + '}')

      else
        buffer('null')

    visitCode = (code) ->
      return unless code
      buffer(code.val)

    visitText = (node) ->
      buffer(JSON.stringify(node.val))

    visitNodes =
      Text: visitText
      Tag: visitTag
      Block: visitBlock

    parts = []
    buffer = (str) -> parts.push(str)
    visit = (node) -> visitNodes[node.type](node)
    visit(node)

    toPush = (part) -> 'buf.push(' + JSON.stringify(part)+ ');'

    buffer('\n')
    return parts.map(toPush).join('\n')

module.exports = Compiler
