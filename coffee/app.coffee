Take ["DOOM", "DOMContentLoaded"], (DOOM)->



  nodes = [
    ["div", {}, [
        ["h1", {textContent: "test"}]
      ]
    ]
  ]

  root = document.querySelector "main"

  render = (parent, [tag, attrs, children])->
    elm = DOOM.create tag, parent, attrs
    if children?.length
      render elm, child for child in children

  for node in nodes
    DOOM.empty root
    render root, node
