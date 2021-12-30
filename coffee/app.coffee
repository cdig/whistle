Take ["DOOM", "DOMContentLoaded"], (DOOM)->

  renderNodes = (data, nodes)->
    for node in nodes
      renderNode data, node

  renderNode = (data, [block, attrs, ...contents])->
    blockFn = getBlockFn block
    elmTemplate = blockFn data, attrs, contents

    # Some html attrs will be generated dynamically
    dynAttrs =
      "#{block.toLowerCase()}-block": "" # Name of the block, like "text-block"

    # Merge the author-provided html attrs with the dynamic attrs into the attrs from the template
    Object.assign elmTemplate[1], dynAttrs, attrs

    if elmTemplate[2] instanceof Array
      elmTemplate.splice 2, 1, renderNodes data, elmTemplate[2]

    elmTemplate

  getBlockFn = (blockName)->
    blocks[blockName] || blocks.default

  renderElement = (parent, [tag, attrs, contents])->
    elm = DOOM.create tag, parent, attrs

    if typeof contents is "string"
      DOOM elm, textContent: contents
    else if contents?.length > 0
      renderElements elm, contents

  renderElements = (parent, elements)->
    for element in elements
      renderElement parent, element


  # DATA ##########################################################################################


  blocks =
    default:   (data, attrs, contents)-> ["div", {}, contents]
    "Title":   (data, attrs, contents)-> ["h1", {}, data.title]
    "Image":   (data, attrs, contents)-> ["img", {src: contents[0]}]
    "Heading": (data, attrs, contents)-> ["h1", {}, contents[0]]
    "Text":    (data, attrs, contents)-> ["p", {}, contents[0]]

  data =
    title: "Energy Basics"
    # Nodes are a minimal representation of the lesson content.
    # We should try to keep them very general, so that we can make changes to
    # the design of the blocks without having to update all our nodes.
    nodes: [
      ["Title"]
      ["Page", {},
        ["Main", {},
          ["Row", {},
            ["Image", {}, "images/system.png"]
            ["Unit", {},
              ["Heading", {alignLeft:""}, "Objectives"]
              ["Text", {}, "In this lesson, we'll discuss the meaning and measurement of basic physics concepts that apply to hydraulic systems: energy, force, work, power, torque, and horsepower."]
            ]
          ]
        ]
      ]
    ]

  # INIT ##########################################################################################

  root = document.querySelector "main"
  DOOM.empty root
  elements = renderNodes data, data.nodes
  renderElements root, elements
