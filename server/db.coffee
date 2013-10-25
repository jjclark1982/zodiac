riak = require("riak-js")
servers = process.env.RIAK_SERVERS.split(/,/)

if servers.length > 1
    db = riak.getClient({pool:{servers: servers, options: {}}})
else
    server = servers[0].split(/:/)
    db = riak.getClient({host: server[0], port: server[1] or 8098})

module.exports = db
