

# node_modules/take-and-make/source/take-and-make.coffee
# Since this is typically the first bit of code included in our big compiled and
# concatenated JS files, this is a great place to demand strictness. CoffeeScript
# does not add strict on its own, but it will permit and enforce it.
"use strict";

# Bail if Take&Make is already running in this scope, or if something else is using our names
unless Take? or Make?

  # We declare our globals such that they're visible everywhere within the current scope.
  # This allows for namespacing — all things within a given scope share a copy of Take & Make.
  Take = null
  Make = null
  DebugTakeMake = null

  do ()->

    made = {}
    waitingTakers = []
    takersToNotify = []
    alreadyWaitingToNotify = false
    alreadyChecking = false
    timeoutsNeeded = 0
    timeoutsUsed = 0

    Make = (name, value = name)->
      # Debug — call Make() in the console to see what we've regstered
      return clone made if not name?

      # Synchronous register, returns value
      register name, value


    Take = (needs, callback)->
      # Debug — call Take() in the console to see what we're waiting for
      return waitingTakers.slice() if not needs?

      # Synchronous and asynchronous resolve, returns value or object of values
      resolve needs, callback


    DebugTakeMake = ()->
      output =
        timeoutsNeeded: timeoutsNeeded
        timeoutsUsed: timeoutsUsed
        unresolved: {}
      for waiting in waitingTakers
        for need in waiting.needs
          unless made[need]?
            output.unresolved[need] ?= 0
            output.unresolved[need]++
      return output


    register = (name, value)->
      throw new Error("You may not Make(\"\") an empty string.") if name is ""
      throw new Error("You may not Make() the same name twice: #{name}") if made[name]?
      made[name] = value
      checkWaitingTakers()
      value


    checkWaitingTakers = ()->
      return if alreadyChecking # Prevent recursion from Make() calls inside notify()
      alreadyChecking = true

      # Comments below are to help reason through the (potentially) recursive behaviour

      for taker, index in waitingTakers # Depends on `waitingTakers`
        if allNeedsAreMet(taker.needs) # Depends on `made`
          waitingTakers.splice(index, 1) # Mutates `waitingTakers`
          notify(taker) # Calls to Make() or Take() will mutate `made` or `waitingTakers`
          alreadyChecking = false
          return checkWaitingTakers() # Restart: `waitingTakers` (and possibly `made`) were mutated

      alreadyChecking = false


    allNeedsAreMet = (needs)->
      return needs.every (name)-> made[name]?


    resolve = (needs, callback)->
      # We always try to resolve both synchronously and asynchronously
      asynchronousResolve needs, callback if callback?
      synchronousResolve needs


    asynchronousResolve = (needs, callback)->
      if needs is ""
        needs = []
      else if typeof needs is "string"
        needs = [needs]

      taker = needs: needs, callback: callback

      if allNeedsAreMet needs
        takersToNotify.push taker
        timeoutsNeeded++
        unless alreadyWaitingToNotify
          alreadyWaitingToNotify = true
          setTimeout notifyTakers # Preserve asynchrony
          timeoutsUsed++
      else
        waitingTakers.push taker


    synchronousResolve = (needs)->
      if typeof needs is "string"
        return made[needs]
      else
        o = {}
        o[n] = made[n] for n in needs
        return o


    notifyTakers = ()->
      alreadyWaitingToNotify = false
      queue = takersToNotify
      takersToNotify = []
      notify taker for taker in queue
      null


    notify = (taker)->
      resolvedNeeds = taker.needs.map (name)-> made[name]
      taker.callback.apply(null, resolvedNeeds)


    # IE11 doesn't support Object.assign({}, obj), so we just use our own
    clone = (obj)->
      out = {}
      out[k] = v for k,v of obj
      out


    # We want to add a few handy one-time events.
    # However, we don't know if we'll be running in a browser, or in node.
    # Thus, we look for the presence of a "window" object as our clue.
    if window?

      addListener = (eventName)->
        window.addEventListener eventName, handler = (eventObject)->
          window.removeEventListener eventName, handler
          Make eventName, eventObject
          return undefined # prevent unload from opening a popup

      addListener "beforeunload"
      addListener "click"
      addListener "unload"

      # Since we have a window object, it's probably safe to assume we have a document object
      switch document.readyState
        when "loading"
          addListener "DOMContentLoaded"
          addListener "load"
        when "interactive"
          Make "DOMContentLoaded"
          addListener "load"
        when "complete"
          Make "DOMContentLoaded"
          Make "load"
        else
          throw new Error "Unknown document.readyState: #{document.readyState}. Cannot setup Take&Make."


    # Finally, we're ready to hand over control to module systems
    if module?
      module.exports = {
        Take: Take,
        Make: Make,
        DebugTakeMake: DebugTakeMake
      }


# node_modules/doom/doom.coffee
do ()->

  svgNS = "http://www.w3.org/2000/svg"
  xlinkNS = "http://www.w3.org/1999/xlink"

  # This is used to cache normalized keys, and to provide defaults for keys that shouldn't be normalized
  attrNames =
    gradientUnits: "gradientUnits"
    preserveAspectRatio: "preserveAspectRatio"
    startOffset: "startOffset"
    viewBox: "viewBox"
    # common case-sensitive attr names should be listed here as needed — see svg.cofee in https://github.com/cdig/svg for reference

  eventNames =
    blur: true
    change: true
    click: true
    focus: true
    input: true
    keydown: true
    keypress: true
    keyup: true
    mousedown: true
    mouseenter: true
    mouseleave: true
    mousemove: true
    mouseup: true
    scroll: true

  propNames =
    childNodes: true
    firstChild: true
    innerHTML: true
    lastChild: true
    nextSibling: true
    parentElement: true
    parentNode: true
    previousSibling: true
    textContent: true
    value: true

  styleNames =
    animation: true
    animationDelay: true
    background: true
    borderRadius: true
    color: true
    display: true
    fontSize: "html" # Only treat as a style if this is an HTML elm. SVG elms will treat this as an attribute.
    fontFamily: true
    fontWeight: true
    height: "html"
    left: true
    letterSpacing: true
    lineHeight: true
    maxHeight: true
    maxWidth: true
    margin: true
    marginTop: true
    marginLeft: true
    marginRight: true
    marginBottom: true
    minWidth: true
    minHeight: true
    opacity: "html"
    overflow: true
    overflowX: true
    overflowY: true
    padding: true
    paddingTop: true
    paddingLeft: true
    paddingRight: true
    paddingBottom: true
    pointerEvents: true
    position: true
    textDecoration: true
    top: true
    transform: "html"
    transition: true
    visibility: true
    width: "html"
    zIndex: true

  # When creating an element, SVG elements require a special namespace, so we use this list to know whether a tag name is for an SVG or not
  svgElms =
    circle: true
    clipPath: true
    defs: true
    g: true
    image: true
    mask: true
    path: true
    rect: true
    svg: true
    text: true
    use: true


  read = (elm, k)->
    if propNames[k]?
      elm._DOOM_prop[k] ?= elm[k]
    else if styleNames[k]?
      elm._DOOM_style[k] ?= elm.style[k]
    else
      k = attrNames[k] ?= k.replace(/([A-Z])/g,"-$1").toLowerCase() # Normalize camelCase into kebab-case
      elm._DOOM_attr[k] ?= elm.getAttribute k


  write = (elm, k, v)->
    if propNames[k]?
      cache = elm._DOOM_prop
      isCached = cache[k] is v
      elm[k] = cache[k] = v if not isCached
    else if styleNames[k]? and !(elm._DOOM_SVG and styleNames[k] is "html")
      cache = elm._DOOM_style
      isCached = cache[k] is v
      elm.style[k] = cache[k] = v if not isCached
    else if eventNames[k]?
      cache = elm._DOOM_event
      return if cache[k] is v
      if cache[k]?
        throw "DOOM experimentally imposes a limit of one handler per event per object."
        # If we want to add multiple handlers for the same event to an object,
        # we need to decide how that interacts with passing null to remove events.
        # Should null remove all events? Probably. How do we track that? Keep an array of refs to handlers?
        # That seems slow and error prone.
      cache[k] = v
      if v?
        elm.addEventListener k, v
      else
        elm.removeEventListener k, v
    else
      cache = elm._DOOM_attr
      return if cache[k] is v
      cache[k] = v
      ns = if k is "xlink:href" then xlinkNS else null # Grab the namespace if needed
      k = attrNames[k] ?= k.replace(/([A-Z])/g,"-$1").toLowerCase() # Normalize camelCase into kebab-case
      if ns?
        if v? # check for null
          elm.setAttributeNS ns, k, v # set DOM attribute
        else # v is explicitly set to null (not undefined)
          elm.removeAttributeNS ns, k # remove DOM attribute
      else
        if v? # check for null
          elm.setAttribute k, v # set DOM attribute
        else # v is explicitly set to null (not undefined)
          elm.removeAttribute k # remove DOM attribute


  act = (elm, opts)->
    # Initialize the caches
    elm._DOOM_attr ?= {}
    elm._DOOM_prop ?= {}
    elm._DOOM_style ?= {}

    if typeof opts is "object"
      for k, v of opts
        write elm, k, v
        null
      return elm
    else if typeof opts is "string"
      return read elm, opts


  # PUBLIC API ####################################################################################

  # The first arg can be an elm or array of elms
  # The second arg can be an object of stuff to update in the elm(s), in which case we'll return the elm(s).
  # Or it can be a string prop/attr/style to read from the elm(s), in which case we return the value(s).
  DOOM = (elms, opts)->
    elms = [elms] unless typeof elms is "array"
    (throw new Error "DOOM was called with a null element" unless elm?) for elm in elms
    throw new Error "DOOM was called with null options" unless opts?
    results = (act elm, opts for elm in elms)
    return if results.length is 1 then results[0] else results


  DOOM.create = (type, parent, opts)->
    if svgElms[type]?
      elm = document.createElementNS svgNS, type
      if type is "svg"
        (opts ?= {}).xmlns = svgNS
      else
        elm._DOOM_SVG = true
    else
      elm = document.createElement type
    DOOM elm, opts if opts?
    DOOM.append parent, elm if parent?
    return elm


  DOOM.append = (parent, child)->
    parent.appendChild child
    return child


  DOOM.prepend = (parent, child)->
    if parent.hasChildNodes()
      parent.insertBefore child, parent.firstChild
    else
      parent.appendChild child
    return child


  DOOM.remove = (elm, child)->
    if child?
      elm.removeChild child if child.parentNode is elm
      return child
    else
      elm.remove()
      return elm


  DOOM.empty = (elm)->
    elm.innerHTML = ""


  # Attach to this
  @DOOM = DOOM if @?

  # Attach to the window
  window.DOOM = DOOM if window?

  # Integrate with Take & Make
  Make "DOOM", DOOM if Make?


# coffee/app.coffee
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
