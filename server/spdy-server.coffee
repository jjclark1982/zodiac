#!/usr/bin/env coffee

spdy = require("spdy")
path = require("path")
fs = require("fs")
expressApp = require('./express-app')

spdyOptions = {
    key: fs.readFileSync(path.resolve(__dirname, "../keys/dev-key.pem")),
    cert: fs.readFileSync(path.resolve(__dirname, "../keys/dev-cert.pem")),
    ca: fs.readFileSync(path.resolve(__dirname, "../keys/dev-csr.pem")),
    windowSize: 1024
}

server = spdy.createServer(spdyOptions, expressApp)
server.on('error', (error)->
    if error.code in ['EADDRINUSE', 'EACCES']
        server.listen(0)
    else
        throw error
)
server.once('listening', ->
    console.log('SPDY server listening on port', server.address().port)
)

module.exports = server

if module is require.main
    server.listen(process.env.PORT or 443)
