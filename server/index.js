#!/usr/bin/env node

// # index.js
// ### Start here

// *This file loads the [node](http://nodejs.org/) server,
// with parameters specified through environment variables.*
// ***

// This module bootstraps support for [CoffeeScript](http://coffeescript.org/)
// so that the server can be started with `node server` even if `coffee` is not in the PATH.
require('coffee-script/register');

// either load into memory [`SPDY.COFFEE`](spdy-server.html) or [`HTTP.COFFEE`](http-server.html), depending on whether
// there is a USE_SPDY flag in the `environment`. If present, this means: use the 
// [SPDY](http://en.wikipedia.org/wiki/SPDY) protocol; otherwise, default to HTTP.
var server;
if (process.env.USE_SPDY) {
    server = require('./spdy-server');
}
else {
    server = require('./http-server');
}

// Provide a `startServer` function for compatibility with [Brunch](http://brunch.io/).
function startServer(port, path, callback) {
    var newCallback = function(){
        // Once the server is running, don't terminate on every error
        process.on("uncaughtException", function(err){
            console.error(err.stack);
        });
        callback.apply(this, arguments)
    };
    
    server.listen(port || process.env.PORT, newCallback);
}

// When launched directly via `node server`, start the server.
if (module === require.main) {
    // If the `environment` directs it, create [node clusters](http://nodejs.org/api/cluster.html)
    // by leveraging [`CLUSTER.COFFEE`](cluster.html)
    if (process.env.USE_CLUSTER) {
        require("./cluster")(startServer);
    }
    else {
        startServer();
    }
}

module.exports = server;
module.exports.startServer = startServer;

// ***
// ***NEXT**: Step into [`SPDY.COFFEE`](spdy-server.html) or [`HTTP.COFFEE`](http-server.html) and observe how
// they instantiate the server that is referenced here.*
