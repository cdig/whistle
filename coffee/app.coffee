Take ["DOOM", "DOMContentLoaded"], (DOOM)->
  nodes = [
    ["h1", {id: "title"}, "Energy Basics"]
    ["section", {},
      ["object", {data: "https://cdn.lunchboxsessions.com/v4-1/c1a8e483b1fb1164d0c511c2572f6109.html"}]
      ["div",
        ["h1", "Objectives"]
        ["p", "In this lesson, we'll discuss the meaning and measurement of basic physics concepts that apply to hydraulic systems: energy, force, work, power, torque, and horsepower."]
      ]
    ]
    ["section", {},
      ["div", {}, ["h3", {textContent: "In a div"}]]
      ["div", {}, ["h3", {textContent: "In a div"}]]
    ]
  ]


  renderElement = (parent, [tag, ...contents])->
    if (contents[0] instanceof Object) and not (contents[0] instanceof Array)
      attrs = contents.shift()

    if attrs?.data?
      attrs.data = attrs.data.replace "//cdn.", "//cdn-dev."

    elm = DOOM.create tag, parent, attrs

    if typeof contents[0] is "string"
      DOOM elm, textContent: contents[0]
    else if contents.length > 0
      renderElement elm, child for child in contents


  render = (root)->
    DOOM.empty root
    for node in nodes
      renderElement root, node


  render document.querySelector "main"
