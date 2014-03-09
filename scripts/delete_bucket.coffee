#!/usr/bin/env coffee

highland = require("highland")
db = require("../server/db")

bucket = process.argv[2]

deleteObject = highland.wrapCallback((key, callback)->
    console.log("Deleting #{bucket}/#{key}")
    db.remove(bucket, key, (err, obj, meta)->
        callback(err, meta)
    )
)

ignore404 = (err, push)->
    if err.statusCode isnt 404
        push(err)
    else
        push(null, err)

query = db.keys(bucket, {keys: 'stream'})
keyListStream = highland('keys', query)
query.on('end', ->keyListStream.end())
keyStream = keyListStream.flatten()

resultStream = keyStream.map(deleteObject).flatten().errors(ignore404)
resultStream.group('statusCode').each((resultsByCode)->
    if Object.keys(resultsByCode).length is 0
        console.log("No items to delete")
    for statusCode, items of resultsByCode
        console.log("#{items.length} items finished with status code #{statusCode}")
)
query.start()
