# # http-server.coffee
# ### Vanilla-flavored express setup

# *This file instantiates an [express](http://expressjs.com/) application with the regular HTTP protocol.*
# ***

#!/usr/bin/env coffee

# Load the [node HTTP module](http://nodejs.org/api/http.html)
http = require('http')

# Load [`EXPRESS.COFFEE`](express-app.html) middleware stack.

expressApp = require('./express-app')

# Instantiate server, passing the [`EXPRESS.COFFEE`](express-app.html) middleware stack.
server = http.createServer(expressApp)

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

# Export the server object
module.exports = server

# Run a [node](http://nodejs.org/) instance if this is run from the command line.
if module is require.main
    server.listen(process.env.PORT or 80)

# ***
# ***NEXT**: Step into the [`EXPRESS.COFFEE`](express-app.html) middleware stack and observe how that stack is formed.*


