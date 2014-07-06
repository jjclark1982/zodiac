db = require("./db")
gatewayError = require("./gateway-error")
global._ = require('lodash')
global.Backbone = require('backbone')
Promise = require('bluebird')

# Convert any ids stored in this model's "_links" attribute
# into the format for storing with riak-js
formatLinks = (model)->
    linkKeys = []
    for linkName, target of model.linkedModels() or {}
        if target
            linkKeys.push({
                tag: linkName
                bucket: target.bucket
                key: target.id
            })
    return linkKeys

Backbone.sync = (method, model={}, options={})->
    promise = new Promise((resolve, reject)->
        idAttribute = model.idAttribute or model.model?.prototype.idAttribute or 'id'
        bucket = model.bucket or model.model?.prototype.bucket
        unless bucket
            throw new Error("cannot #{method} a model that has no bucket defined")

        callback = (err, object={}, meta={})->
            if err then return reject(gatewayError(err))

            # make sure the id gets filled in if it was provided by riak
            object[idAttribute] = meta.key

            # attach essential metadata to the model
            model.vclock = meta.vclock
            model.lastMod = meta.lastMod
            model.etag = meta.etag

            # attach additional metadata to the model
            model.metadataFromRiak = meta

            resolve(object)

        switch method
            when "create", "update"
                unless model.isValid()
                    return reject(model.validationError)

                options.returnbody ?= true
                options.vclock ?= model.vclock
                
                if model.index
                    options.index ?= _.result(model, 'index')

                links = formatLinks(model)
                if links?.length > 0
                    options.links = links

                db.save(bucket, model.id, model.toJSON(), options, callback)

            when "delete"
                db.remove(bucket, model.id, options, callback)

            when "read"
                if model instanceof Backbone.Model
                    db.get(bucket, model.id, options, callback)

                else if model instanceof Backbone.Collection
                    collection = model
                    # assume the default query if none is provided, but do not redirect to it
                    query = options.query
                    fullOrder = query.order or idAttribute
                    orderParts = fullOrder.split(' ') # TODO: support multiple keys with comma
                    [sortKey, sortDirection] = orderParts
                    delete query.order
                    if Object.keys(query).length is 0
                        query.all = '1'

                    if true
                        db.mapreduce
                        .add(bucket) # TODO: use 2i
                        .map('Riak.mapValuesJson')
                        .reduce(sort, {by: sortKey, order: sortDirection})
                        .run((err, values=[], meta)->
                            if err then return reject(gatewayError(err))
                            resolve(values)
                        )
                    else if options.streamAllKeys
                        items = []
                        db.keys(bucket, {keys: 'stream'}, (err, keys, meta)->
                            if err then return reject(gatewayError(err))
                            resolve(items)
                        ).on('keys', (keys=[])->
                            for key in keys
                                item = {}
                                item[idAttribute] = key
                                items.push(item)
                        ).start()
                    else
                        db.query(bucket, query, options, (err, keys=[], meta)->
                            if err then return reject(gatewayError(err))
                            items = []
                            for key in keys
                                item = {}
                                item[idAttribute] = key
                                items.push(item)
                            resolve(items)
                        )
                    # TODO: support fetching model data in a collection through some option
                    return

            else
                throw new Error("cannot #{method} a model")

        model.trigger('request', model, {}, options);
    )

    promise.then(options.success, options.error)

    return promise

module.exports = Backbone.sync

sort = (values, arg) ->
    field = arg?.by
    reverse = arg?.order is 'desc'
    values.sort((a, b)->
        if reverse then [a,b] = [b,a]
        if a?[field] < b?[field] then -1
        else if a?[field] is b?[field] then 0
        else if a?[field] > b?[field] then 1
    )
