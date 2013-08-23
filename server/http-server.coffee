#!/usr/bin/env coffee

http = require('http')
expressApp = require('./express-app')

server = http.createServer(expressApp)

server.on('error', (error)->
    if error.code in ['EADDRINUSE', 'EACCES']
        server.listen(0)
    else
        throw error
)

server.once('listening', ->
    console.log('HTTP server listening on port', server.address().port)
)

module.exports = server

if module is require.main
    server.listen(process.env.PORT or 80)
