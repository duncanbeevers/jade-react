# jade-react

Compile Jade templates to React de-sugared JSX.

````jade
div.first
.second
a(href="static")
a(href=dynamic)
p Static Content
p= dynamicContent
p
  | Text
p
  | Multiline Text 1
  | Multiline Text 2
ul
  li List Item
  li= dynamicListItem
div.staticClass1(class="staticClass2")
div.staticClass1(class=dynamicClass2)
````

into

````javascript
React.DOM.div({"class":"first"}) +
React.DOM.div({"class":"second"}) +
React.DOM.a({"href":"static"}) +
React.DOM.a({"href":dynamic}) +
React.DOM.p(null, "Static Content") +
React.DOM.p(null, dynamicContent) +
React.DOM.p(null, "Text") +
React.DOM.p(null, "Multiline Text 1" + "Multiline Text 2") +
React.DOM.ul(null, React.DOM.li(null, "List Item") + React.DOM.li(null, dynamicListItem)) +
React.DOM.div({"class":"staticClass1 staticClass2"}) +
React.DOM.div({"class":"staticClass1" + " " + dynamicClass2})
````
