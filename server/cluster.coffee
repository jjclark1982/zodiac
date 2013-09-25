# Load the node [`cluster` module](http://nodejs.org/api/cluster.html)
cluster = require("cluster")

# EXPORT a function that runs the given task on each CPU of the current machine
module.exports = (task)->
    if (cluster.isMaster)
        numCPUs = require("os").cpus().length
        for [1..numCPUs]
            cluster.fork()
    else
        task?()
