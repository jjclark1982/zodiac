#!/usr/bin/env coffee

# Open an interactive prompt

fs = require("fs")
packageDef = require("../package")

moduleName = (filename)->
    # helper function to change a filename into a symbol name
    # e.g.: express-app.coffee -> expressApp
    return filename.replace(/\..*?$/, '').replace(/[\W]+(.)?/g, (match, c)->
        c?.toUpperCase() or ""
    )

repl = require('coffee-script/lib/coffee-script/repl')
session = repl.start({prompt: "#{packageDef.name}> "})

# pre-populate the context with server files and models
context = session.context
for file in fs.readdirSync(__dirname+"/../server") when file[0] isnt '.'
    try
        context[moduleName(file)] = require("../server/#{file}")
    catch e
        null

for modelName, ModelCtor of require("../client/models")
    context[ModelCtor.name] = ModelCtor
