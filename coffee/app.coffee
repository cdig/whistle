fs = require "fs"

Take ["DOOM", "DOMContentLoaded"], (DOOM)->

  languageIndex = 0
  languages = ["English", "Spanish"]

  blocks =
    default:       (data, attrs, contents)-> ["div", {}, contents]
    "Title":       (data, attrs, contents)-> ["h1", {}, contents[0]]
    "Image":       (data, attrs, contents)-> ["img", {src: contents[0]}]
    "Heading":     (data, attrs, contents)-> ["h1", {}, contents[0]]
    "Text":        (data, attrs, contents)-> ["p", {}, contents[0]]
    "BulletList":  (data, attrs, contents)-> ["ul", {}, contents]
    "ListItem":    (data, attrs, contents)-> ["li", {}, contents[0]]
    "Caption":     (data, attrs, contents)-> ["div", {class: "caption"}, contents[0]]


  renderNodes = (data, nodes)->
    for node in nodes
      renderNode data, node

  toKebab = (s)->
    s.replace(/([a-z])([A-Z])/g,"$1-$2").toLowerCase()

  renderNode = (data, [block, attrs, ...contents])->

    if attrs?.i?
      languageName = languages[languageIndex]
      strings = data.languages[languageName]
      contents = [strings[attrs.i]]

    blockFn = getBlockFn block
    elmTemplate = blockFn data, attrs, contents

    # Some html attrs will be generated dynamically
    dynAttrs =
      "#{toKebab block}-block": "" # Name of the block, like "text-block"

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
      DOOM elm, innerHTML: contents
    else if contents?.length > 0
      renderElements elm, contents

  renderElements = (parent, elements)->
    for element in elements
      renderElement parent, element

  render = (data)->
    DOOM.empty root
    elements = renderNodes data, data.nodes
    renderElements root, elements


  # INIT ##########################################################################################

  root = document.querySelector "main"
  data = JSON.parse fs.readFileSync "build/data.json"
  render data


  # Buttons #######################################################################################

  languageButton = document.querySelector "[btn-language]"
  unitsButton = document.querySelector "[btn-units]"

  languageButton.addEventListener "click", ()->
    languageIndex = ++languageIndex % languages.length
    render data

  # Light / Dark Mode #############################################################################

  updateTheme = (isDark)->
    document.documentElement.classList.toggle "dark", isDark
    document.documentElement.classList.toggle "light", !isDark

  # This will store which theme the user has selected, if any
  isDark = null

  # You can use the button to manually set the theme
  themeButton = document.querySelector "[btn-theme]"
  themeButton.addEventListener "click", ()->
    isDark ?= window.matchMedia("(prefers-color-scheme: dark)").matches
    isDark = !isDark
    updateTheme isDark

  # But until the theme is manually set, we'll just match the OS whenever it changes
  window.matchMedia("(prefers-color-scheme: dark)").addEventListener "change", (e)->
    updateTheme e.matches unless isDark?

  # And here we do the initial sync to the OS setting
  updateTheme window.matchMedia("(prefers-color-scheme: dark)").matches
