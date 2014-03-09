db = require("./db")
global._ = require('lodash')
global.Backbone = require('backbone')
Promise = require('bluebird')

# Convert any ids stored in this model's "_links" attribute
# into the format for storing with riak-js
formatLinks = (model)->
    linkKeys = []
    for linkName, target of model.linkedModels() or {}
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
            if err then return reject(err)

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
                if model instanceof Backbone.Collection
                    collection = model
                    query = collection.query or {all: '1'} # or parse collection.url??
                    db.query(bucket, query, options, (err, keys=[], meta)->
                        if err then return reject(err)
                        items = []
                        for key in keys
                            item = {}
                            item[idAttribute] = key
                            items.push(item)
                        # TODO: fetch model data as well???
                        # collection url -> list of model ids -> model data
                        resolve(items)
                    )
                    return

                db.get(bucket, model.id, options, callback)

            else
                throw new Error("cannot #{method} a model")

        model.trigger('request', model, {}, options);
    )

    promise.then(options.success, options.error)

    return promise

module.exports = Backbone.sync
