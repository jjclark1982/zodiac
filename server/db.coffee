riak = require("riak-js")

unless process.env.RIAK_SERVERS
    console.error("Cannot connect to database: RIAK_SERVERS environment variable must be set")

servers = process.env.RIAK_SERVERS.split(/,/)

if servers.length > 1
    db = riak.getClient({pool:{servers: servers, options: {
        keepAlive: true
        ping: '/'
    }}})
else
    server = servers[0].split(/:/)
    db = riak.getClient({host: server[0], port: server[1] or 8098})

module.exports = db
