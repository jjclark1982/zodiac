#!/usr/bin/env coffee

spdy = require("spdy")
path = require("path")
fs = require("fs")
# Load [`EXPRESS.COFFEE`](express-app.html)
expressApp = require('./express-app')

# Set `SPDY` options, in this case: certs and windowsize
spdyOptions = {
    key: fs.readFileSync(path.resolve(__dirname, "../keys/dev-key.pem")),
    cert: fs.readFileSync(path.resolve(__dirname, "../keys/dev-cert.pem")),
    ca: fs.readFileSync(path.resolve(__dirname, "../keys/dev-csr.pem")),
    windowSize: 1024
}

# Instantiate server, passing options and the [`express middleware`](express-app.html)
server = spdy.createServer(spdyOptions, expressApp)

# Add listener to throw errors on error
server.on('error', (error)->
    if error.code in ['EADDRINUSE', 'EACCES']
        server.listen(0)
    else
        throw error
)
# `console.log()` the port, once running
server.once('listening', ->
    console.log('SPDY server listening on port', server.address().port)
)

module.exports = server

if module is require.main
    server.listen(process.env.PORT or 443)
