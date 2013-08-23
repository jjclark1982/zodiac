cluster = require("cluster")

module.exports = (task)->
    if (cluster.isMaster)
        numCPUs = require("os").cpus().length
        for [1..numCPUs]
            cluster.fork()
    else
        task?()
