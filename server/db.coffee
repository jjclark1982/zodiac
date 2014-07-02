riak = require("riak-js")

unless process.env.RIAK_SERVERS
    console.error("Cannot connect to database: RIAK_SERVERS environment variable must be set")

servers = (process.env.RIAK_SERVERS or '').split(/,/)

if servers.length > 1
    riakOptions = {
        pool: {
            servers: servers,
            options: {
                keepAlive: true,
                ping: '/'
            }
        }
    }
else
    server = servers[0].split(/:/)
    riakOptions = {
        host: server[0],
        port: server[1] or 8098
    }

db = riak.getClient(riakOptions)

db.ping((err, isAlive)->
    if !isAlive
        console.error("Unable to establish connection to riak server "+servers)
)

module.exports = db
