###
Simple effective asynchronous module requirements for the browser.

Dependencies are only loaded once - the first time they are referenced. Afterwards
the same in-memory instance is used. By using 'depends' when the information is 
referenced in a parent module means that code is loaded on demand - giving a responsive
UI without resorting to combining script files.

If run on the uSDLC-node-server, translation to js from coffeescript, etc is transparent.
This means any supported language will work (coffee-script, live-script, clojure-script, etc)

In the example below script 'a' depends on script 'b'. The closure is only run
after script 'b' was loaded. Script 'b' in turn relies on script 'c'. In the end
the log is only written to and the value checked after scripts a, b and c are all
loaded.

#a.coffee:
depends 'b', (b) ->
  console.log b.name
  throw 'wrong' if b.value isnt 1
  
  depends 'c', (c) ->
    throw 'wrong' if c isnt 2
    
    dependsforceReload 'c'
    depends 'c', (c) ->
      throw 'wrong' if c isnt 1 # reset as c.js is reloaded

#b.coffee
->
  depends 'c', (c) ->
    return
      name: "bee"
      value: c()

#c.js
function() {
  counter = 1
  return function() {counter++}
}
###
depends = (url, callback) ->  
  return callback code if code = depends.cache[url]

  url += ".coffee"
  globalVar = "_dependency_#{depends.scriptIndex++}"

  script = document.createElement("script")
  script.type = "text/javascript"
  script.async = "async"
  onScriptLoaded = ->
    code = depends.cache[url] = window[globalVar]() ? {}
    delete window[globalVar]
    callback code

  if script.readyState # IE
    script.onreadystatechange = ->
      if script.readyState == "loaded" || script.readyState == "complete"
        script.onreadystatechange = null;
        onScriptLoaded();
  else # Other browsers
   script.onload = -> onScriptLoaded()

  script.src = "#{url}?globalVar=#{globalVar}"
  head.appendChild(script)

depends.scriptIndex = 0
depends.cache = {}

###
Use forceReload if a module source has changed (edited on browser, for example)
###
depends.forceReload = (url) -> delete depends.cache[url]