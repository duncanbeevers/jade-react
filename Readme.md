# jade-react

Compile Jade templates to React de-sugared JSX.

```jade
.container-fluid.readme
  .row
    h1= this.storeName
    ul
    each product in this.products
      li
        | Product
        = product.title
```

into

```javascript
function () {
  function map (obj, fn) {
    if ('number' === typeof obj.length) return obj.map(fn);
    var result = [], key, hasProp = {}.hasOwnProperty;
    for (key in obj) hasProp.call(obj, key) && result.push(fn(key, obj[key]));
    return result;
  }

  return React.DOM.div({
    "className": "container-fluid readme"
  },
    React.DOM.div({
      "className": "row"
    },
      React.DOM.h1(null,
        this.storeName
      ),
      React.DOM.ul(null),
        map(this.products, function (product, $index) {
          return React.DOM.li(null,
            "Product",
            product.title
          );
        }
      )
    )
  );
}
```
