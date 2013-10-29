#!/usr/bin/env coffee

_ = require("lodash")
async = require("async")

db = require("../server/db")

bucket = process.argv[2]

allKeys = []
db.keys(bucket, {keys: 'stream'}, (err, keys, meta)->
    if err then return console.error("Error getting keys:", err)

    async.mapSeries(allKeys, (key, callback)->
        console.log("Deleting #{bucket}/#{key}")
        db.remove(bucket, key, callback)
    , (err)->
        if err
            console.log("Error:", err)
        else
            console.log("Deleted #{allKeys.length} items")
    )
).on('keys', (keys=[])->
    for key in keys
        allKeys.push(key)
).start()
