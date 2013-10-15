#!/usr/bin/env coffee

# # spdy-server.coffee
# ### SPeeDY express setup

# *This file instantiates an [express](http://expressjs.com/) application
# with the [SPDY](http://en.wikipedia.org/wiki/SPDY) protocol,
# a performance-optimized alternative to [HTTPS](http://en.wikipedia.org/wiki/HTTP_Secure).*
# ***

spdy = require("spdy")
path = require("path")
fs = require("fs")
# Load [`EXPRESS.COFFEE`](express-app.html) middleware stack.
expressApp = require('./express-app')

# Set `SPDY` options: in this case, certs and windowsize
spdyOptions = {
    key: fs.readFileSync(path.resolve(__dirname, "../keys/dev-key.pem")),
    cert: fs.readFileSync(path.resolve(__dirname, "../keys/dev-cert.pem")),
    ca: fs.readFileSync(path.resolve(__dirname, "../keys/dev-csr.pem")),
    windowSize: 1024
}

# Instantiate server, passing options and the [`express middleware`](express-app.html) stack.
server = spdy.createServer(spdyOptions, expressApp)

# Add listener to catch errors. If the error is that the port is already in use, pick a different port at 
# random (`server.listen(0)` picks a random port).
server.on('error', (error)->
    if error.code in ['EADDRINUSE', 'EACCES']
        server.listen(0)
    else
        throw error
)
# `console.log()` the port, once running (i.e. the server is listening for requests)
server.once('listening', ->
    console.log('SPDY server listening on port', server.address().port)
)

# Export the server object
module.exports = server

# Run a [node](http://nodejs.org/) instance if this is run from the command line.
if module is require.main
    server.listen(process.env.PORT or 443)

# ***
# ***NEXT**: Step into the [`EXPRESS.COFFEE`](express-app.html) middleware stack and observe how that stack is formed.*
