#!/usr/bin/env coffee

# # http-server.coffee
# ### Vanilla-flavored express setup

# *This file instantiates an [express](http://expressjs.com/) application with the regular HTTP protocol.*
# ***

# Load the [node HTTP module](http://nodejs.org/api/http.html)
http = require('http')

# Load [`EXPRESS.COFFEE`](express-app.html) middleware stack.

expressApp = require('./express-app')

# Instantiate server, passing the [`EXPRESS.COFFEE`](express-app.html) middleware stack.
server = http.createServer((req, res)->
    if server.gracefullyClosing
        res.writeHead(503, {
            "Connection": "close"
            "Content-Type": "text/plain"
            "Retry-After": server.timeout/1000|0
        })
        res.end("Server is in the process of restarting")
    else
        expressApp(req, res)
)
server.timeout = 30*1000

# Support stopping the server gracefully
process.on("SIGTERM", ->
    server.gracefullyClosing = true
    console.log("Received kill signal (SIGTERM), shutting down gracefully.")
    server.close(->
        console.log("Closed out remaining connections.")
        process.exit()
    )
    setTimeout(->
        console.error("Could not close connections in time, forcefully shutting down.")
        process.exit(1)
    , server.timeout)
)

# Add listener to throw errors on error. If the error is that the port is already in use, pick a different port at 
# random (`server.listen(0)` picks a random port).
server.on('error', (error)->
    if error.code in ['EADDRINUSE', 'EACCES']
        server.listen(0)
    else
        throw error
)

# `console.log()` the port, once running (i.e. the server is listening for requests)
server.once('listening', ->
    console.log('HTTP server listening on port', server.address().port)
)

# Support auto-reloading when source code changes
if process.env.NODE_ENV is 'development'
    chokidar = require("chokidar")
    _ = require("lodash")

    reloadApp = ->
        expressApp = null
        for moduleId of require.cache when moduleId.indexOf("node_modules") is -1
            delete require.cache[moduleId]
        console.log("Reloading Express App")
        expressApp = require("./express-app")

    watcher = chokidar.watch([__dirname, __dirname+"/../client"])
    setTimeout(->
        watcher.on("all", _.throttle(reloadApp, 1000))
    , 5000)


# Export the server object
module.exports = server

# Run a [node](http://nodejs.org/) instance if this is run from the command line.
if module is require.main
    server.listen(process.env.PORT or 80)

# ***
# ***NEXT**: Step into the [`EXPRESS.COFFEE`](express-app.html) middleware stack and observe how that stack is formed.*
