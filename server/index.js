#!/usr/bin/env node

// This module bootstraps support for [CoffeeScript](http://coffeescript.org/)
// so that the server can be started with `node` even if `coffee` is not in the PATH.
require('coffee-script');
var server;
if (process.env.USE_SPDY) {
    server = require('./spdy-server');
}
else {
    server = require('./http-server');
}

// Provide a `startServer` function for compatibility with [Brunch](http://brunch.io/).
function startServer(port, path, callback) {
    server.listen(port || process.env.PORT, callback);
}

// When launched directly via `node server`, start the server.
if (module === require.main) {
    startServer();
}

module.exports = {
    server: server,
    startServer: startServer
};
