chokidar = require "chokidar"
coffeescript = require "coffeescript"
fs = require "fs"
sass = require "sass"
{execSync, exec} = require "child_process"

# CONFIG ##########################################################################################

deps =
  coffee: [
    "submodule/bucket/monkey-patch.coffee"
    "node_modules/take-and-make/source/take-and-make.coffee"
    "node_modules/doom/doom.coffee"
  ]
  scss: [
    "submodule/house-style/fonts.css"
    "submodule/house-style/reset.css"
    "submodule/house-style/vars.css"
  ]
  static: [
    "node_modules/d3-color/dist/d3-color.min.js"
  ]

# HELPERS #########################################################################################

# Who needs chalk when you can just roll your own ANSI escape sequences
do ()->
  for color, n of red: "31", green: "32", yellow: "33", blue: "34", magenta: "35", cyan: "36"
    do (color, n)-> global[color] = (t)-> "\x1b[#{n}m" + t + "\x1b[0m"

# For ignoring
dotfiles = /(^|[\/\\])\../

# Print out logs with nice-looking timestamps
arrow = blue " → "
time = ()-> new Date().toLocaleTimeString "en-US", hour12: false
log = (msg)-> console.log yellow(time()) + arrow + msg

# Errors should show a notification and beep
err = (title, msg)->
  exec "osascript -e 'display notification \"Error\" with title \"#{title}\"'"
  exec "osascript -e beep"
  log msg

# Get paths to all source code files of a given type in the project, including deps
# It's assumed the source folder will be named to match the file extension.
getSourcePaths = (type)->
  paths = execSync("fd . -e #{type} #{type}").toString().split("\n")
  paths = paths[...-1] # Drop the last item in the array, because it's just an empty string
  paths = deps[type].concat paths

# Given a list of paths to files, get the contents of each file
readFiles = (filePaths)->
  for filePath in filePaths
    fs.readFileSync(filePath).toString()

# Given a file type, a list of paths to files, and the contents of each file,
# return a list of contents with the filename prepended as a comment.
prependFilenames = (comment, paths, contents)->
  for path, i in paths
    comment + " " + path + "\n\n" + contents[i]

# Watch any given paths, and rerun the task whenever those paths are touched
watch = (paths, task)->
  timeout = null
  run = ()-> doInvoke task
  chokidar.watch paths, ignored: dotfiles, ignoreInitial: true
  .on "error", ()-> err "Watch #{task}", red "Watching #{task} failed."
  .on "all", (event, path)->
    clearTimeout timeout
    timeout = setTimeout run, 10

doInvoke = (task)->
  log task
  invoke task

# TASKS ###########################################################################################

task "coffee", "Compile the CoffeeScript for this project.", ()->
  paths = getSourcePaths "coffee"
  contents = readFiles paths
  concatenated = prependFilenames("#", paths, contents).join "\n\n"
  try
    compiled = coffeescript.compile concatenated, bare: true, inlineMap: true
    fs.writeFileSync "build/app.js", compiled
  catch outerError
    # We hit an error while compiling. To improve the error message, try to compile each
    # individual source file, and see if any of them hit an error. If so, log that.
    for content, i in contents
      try
        coffeescript.compile content, bare: true
      catch innerError
        [msg, mistake, pointer] = innerError.toString().split "\n"
        [_, msg] = msg.split ": error: "
        num = innerError.location.first_line + " "
        pointer = pointer.padStart pointer.length + num.length
        return err "CoffeeScript", [red(paths[i]) + arrow + msg, "", blue(num) + mistake, pointer].join "\n"
    err "CoffeeScript", outerError

task "scss", "Compile the SCSS for this project.", ()->
  paths = getSourcePaths "scss"
  contents = readFiles paths
  concatenated = prependFilenames("//", paths, contents).join "\n\n"
  try
    compiled = sass.compileString(concatenated, sourceMap: false).css
    fs.writeFileSync "build/app.css", compiled
  catch outerError
    # We hit an error while compiling. To improve the error message, try to compile each
    # individual source file, and see if any of them hit an error. If so, log that.
    # Note — this won't work if you define SCSS variables that are meant to be shared between files!
    # So don't do that. Just use CSS variables.
    for content, i in contents
      try
        compiled = sass.compileString(content, sourceMap: false, alertColor: false).css
      catch innerError
        [msg, _, mistake, pointer] = innerError.toString().split "\n"
        [num, mistake] = mistake.split " │"
        [_, pointer] = pointer.split " │"
        pointer = pointer.padStart(pointer.length + num.length)
        return err "SCSS", [red(paths[i]) + arrow + msg, "", blue(num) + mistake, red(pointer)].join "\n"
    err "SCSS", outerError


task "deps", "Copy all static dependencies into the build folder.", ()->
  for dep in deps.static
    execSync "cp #{dep} build"

task "watch", "Whenever source files change, recompile those files.", ()->
  watch ["submodule/bucket/monkey-patch.coffee", "coffee/**/*.coffee"], "coffee"
  watch ["scss/**/*.scss"], "scss"

task "electron", "Start electron.", ()->
  exec "yarn electron ."

task "build", "Run coffee, scss, deps.", ()->
  doInvoke "coffee"
  doInvoke "scss"
  doInvoke "deps"

task "start", "Run build, electron, and watch.", ()->
  doInvoke "build"
  doInvoke "electron"
  doInvoke "watch"
