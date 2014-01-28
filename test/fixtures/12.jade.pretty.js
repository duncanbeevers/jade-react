function () {
  function map (obj, fn) {
    if ('number' === typeof obj.length) return obj.map(fn);
    var result = [], key, hasProp = {}.hasOwnProperty;
    for (key in obj) hasProp.call(obj, key) && result.push(fn(key, obj[key]));
    return result;
  }

  return React.DOM.ul(null,
      map(products, function (product, $index) {
        return React.DOM.li(null,
          "Product",
          product.name
        );
      }
    )
  );
}
