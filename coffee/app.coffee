Take ["DOOM", "DOMContentLoaded"], (DOOM)->
  fs = require "fs"

  editor = new MediumEditor "[editable]",
    disableReturn: true
    disableExtraSpaces: true
    buttonLabels: false
    imageDragging: false
    placeholder:
      text: "…"
      hideOnClick: true
    toolbar:
      buttons: ["bold", "italic", "anchor"]
    anchorPreview:
      hideDelay: 1000000
    keyboardCommands:
      commands: [
        { command: 'bold', key: 'b', meta: true, shift: false }
        { command: 'italic', key: 'i', meta: true, shift: false }
      ]


  languageIndex = 0
  languages = ["English", "Spanish"]

  editable = ""

  blocks =
    default:       (data, attrs, contents)-> ["div", {}, contents]
    "Insert":      (data, attrs, contents)-> ["div", {}, "<div>+</div>"]
    "Title":       (data, attrs, contents)-> ["h1", {editable}, contents[0]]
    "Image":       (data, attrs, contents)-> ["img", {src: contents[0]}]
    "Heading":     (data, attrs, contents)-> ["h1", {editable}, contents[0]]
    "Text":        (data, attrs, contents)-> ["p", {editable}, contents[0]]
    "Bullet List": (data, attrs, contents)-> ["ul", {}, contents]
    "List Item":   (data, attrs, contents)-> ["li", {editable}, contents[0]]
    "Caption":     (data, attrs, contents)-> ["div", {editable, class: "caption"}, contents[0]]


  renderNodes = (data, nodes)->
    for node in nodes
      renderNode data, node

  toKebab = (s)->
    s.replace(/[ -]+/, "-").replace(/([a-z])([A-Z])/g,"$1-$2").toLowerCase()

  getBlockFn = (blockName)->
    blocks[blockName] || blocks.default

  renderNode = (data, [blockName, blockAttrs, ...blockContents])->

    if blockAttrs?.i?
      languageName = languages[languageIndex]
      strings = data.languages[languageName]
      blockContents = [strings[blockAttrs.i]]

    blockFn = getBlockFn blockName
    [elmTag, elmAttrs, elmContents] = blockFn data, blockAttrs, blockContents

    # Some html attrs will be generated dynamically
    dynAttrs =
      "block": blockName
      "#{toKebab blockName}-block": "" # Name of the block, like "text-block"

    # Merge the author-provided html attrs with the dynamic attrs into the attrs from the template
    Object.assign elmAttrs, dynAttrs, blockAttrs

    # Strip the i18n identifier
    delete elmAttrs.i

    if elmContents instanceof Array
      nodes = elmContents
      nodes = addInsertNodes nodes unless blockName in ["Bullet List"]
      elmContents = renderNodes data, nodes

    [elmTag, elmAttrs, elmContents]

  addInsertNodes = (nodes)->
    return nodes # TEMP
    # Add an Insert node after every other node
    nodes
      .map (node)-> [["Insert"], node]
      .flat 1
      .concat [["Insert"]]

  renderElement = (parent, [tag, attrs, contents], nodes, i)->
    elm = DOOM.create tag, parent, attrs

    if typeof contents is "string"
      DOOM elm, innerHTML: contents
    else if contents?.length > 0
      renderElements elm, contents

    if attrs.block is "Insert"
      elm.addEventListener "click", ()->
        console.log nodes
        nodes.splice i, 0, ["Page Break", {}]
        render data

    if attrs.editable?
      requestAnimationFrame ()->
        editor.addElements elm
        editor.setup() unless editor.isActive

  renderElements = (parent, elements, nodes)->
    for element, i in elements
      renderElement parent, element, nodes, i

  renderRoot = (data, root)->
    DOOM.empty root
    elements = renderNodes data, addInsertNodes data.nodes
    renderElements root, elements, data.nodes

  render = (data)->
    renderRoot data, document.querySelector "#wide"
    renderRoot data, document.querySelector "#thin"


  # INIT ##########################################################################################

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
  # window.matchMedia("(prefers-color-scheme: dark)").addEventListener "change", (e)->
  #   updateTheme e.matches unless isDark?

  # And here we do the initial sync to the OS setting
  # updateTheme window.matchMedia("(prefers-color-scheme: dark)").matches

  # META ##########################################################################################

  meta = false
  editing = null

  window.addEventListener "keydown", (e)-> setMeta true if e.key is "Meta"
  window.addEventListener "keyup", (e)-> setMeta false if e.key is "Meta"

  setMeta = (to)->
    document.body.classList.toggle "meta", meta = to

  window.addEventListener "mousemove", (e)->
    if meta
      for elm in e.composedPath() when elm?.hasAttribute? "block"
        return setEditing elm
    setEditing null

  setEditing = (to)->
    return if editing is to
    DOOM editing, editing: null if editing?
    editing = to
    DOOM editing, editing: "" if editing?
