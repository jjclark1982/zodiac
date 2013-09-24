# Load the node [`cluster` module](http://nodejs.org/api/cluster.html)
cluster = require("cluster")

# EXPORT a function that maps node clusters to number of CPUs on current machine
module.exports = (task)->
    if (cluster.isMaster)
        numCPUs = require("os").cpus().length
        for [1..numCPUs]
            cluster.fork()
    else
        task?()
