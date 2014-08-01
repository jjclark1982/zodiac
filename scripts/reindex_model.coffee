#!/usr/bin/env coffee

# Re-save a bucket with the latest 'index' function.

highland = require("highland")
db = require("../server/db")
require("../server/backbone-sync-riak")

modelName = process.argv[2]
try
    Model = require("models/"+modelName)
    console.log("Reindexing each instance of", Model.name)
catch e
    console.error("Could not load models/"+modelName)
    process.exit(1)


bucket = Model.prototype.bucket
idAttribute = Model.prototype.idAttribute

loadModel = highland.wrapCallback((key, callback)->
    attrs = {}
    attrs[idAttribute] = key
    model = new Model(attrs)
    model.fetch().then(->
        callback(null, model)
    , callback)
)

saveModel = highland.wrapCallback((model, callback)->
    headers = {
        "X-Riak-Meta-Modified-By": model.metadataFromRiak._headers['x-riak-meta-modified-by']
    }
    model.save({wait: true, validate: false, headers: headers}).then(->
        callback(null, {statusCode: 200})
    , callback)
)

collectErrors = (err, push)->
    push(null, err)

query = db.keys(bucket, {keys: 'stream'})
keyListStream = highland('keys', query)
query.on('end', ->keyListStream.end())
keyStream = keyListStream.flatten()

modelStream = keyStream.map(loadModel).flatten()
resultStream = modelStream.map(saveModel).flatten()
resultStream.errors(collectErrors).group('statusCode').each((resultsByCode)->
    if Object.keys(resultsByCode).length is 0
        console.log("No items to reindex")
    for statusCode, items of resultsByCode
        console.log("#{items.length} items finished with status code #{statusCode}")
)
query.start()
