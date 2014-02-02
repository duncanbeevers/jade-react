function () {
  return React.DOM.div(
    {
      "className": "div"
    },
    (
      if (this.storeName === 'Reef') {
        React.DOM.h1(null,
          "Reef"
        )
      } else if (this.storeName) {
        React.DOM.h2(null,
          this.storeName
        )
      } else {
        React.DOM.h2(null,
          "No Name"
        )
      }
    )
  );
}
