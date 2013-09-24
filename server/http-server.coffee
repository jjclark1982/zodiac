#!/usr/bin/env coffee

http = require('http')
# Load [`EXPRESS.COFFEE`](express-app.html)
expressApp = require('./express-app')
# Instantiate server, passing the [`express middleware`](express-app.html)
server = http.createServer(expressApp)

# Add listener to throw errors on error
server.on('error', (error)->
    if error.code in ['EADDRINUSE', 'EACCES']
        server.listen(0)
    else
        throw error
)

# `console.log()` the port, once running
server.once('listening', ->
    console.log('HTTP server listening on port', server.address().port)
)

module.exports = server

if module is require.main
    server.listen(process.env.PORT or 80)
