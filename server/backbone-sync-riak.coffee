db = require("./db")
global._ = require('lodash')
global.Backbone = require('backbone')
Promise = require('bluebird')

Backbone.sync = (method, model={}, options={})->
    promise = new Promise((resolve, reject)->
        idAttribute = model.idAttribute or model.model?.prototype.idAttribute or 'id'
        bucket = model.bucket or model.model?.prototype.bucket
        unless bucket
            throw new Error("cannot #{method} a model that has no bucket defined")

        callback = (err, object={}, meta={})->
            if err then return reject(err)

            object[idAttribute] = meta.key
            model.vclock = meta.vclock
            model.lastMod = meta.lastMod
            model.etag = meta.etag
            options.headers ?= {}
            for key, val of meta._headers when key.match(/^x-riak/i)
                options.headers[key] = val
            options.meta = meta # TODO: extract just the needed info?
            
            resolve(object)

        switch method
            when "create", "update"
                unless model.isValid()
                    return reject(model.validationError)

                options.returnbody ?= true
                options.vclock ?= model.vclock
                
                if model.index
                    options.index ?= _.result(model, 'index')

                links = model.linkKeys?()
                if links
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
