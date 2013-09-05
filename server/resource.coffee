express = require('express')
async = require('async')
riak = require("riak-js")
servers = process.env.RIAK_SERVERS.split(/,/)

db = riak.getClient({pool:{servers: servers, options: {}}})

# app.get('/activities/:id', (req, res, next)->
#     db.get('activities', req.params.id, {}, (err, object, meta)->
#         if err then return next(err)
#         res.json(object)
#     )
# )

# app.get('/activities_by_city/:city', (req, res, next)->
#     db.query('activities', {city: req.params.city}, (err, keys, meta)->
#         if err then return next(err)
#     )
# )
global._ = require('lodash')
global.Backbone = require('backbone')

module.exports = (modelCtor)->
    modelName = modelCtor.name
    modelProto = modelCtor.prototype
    bucket = modelProto.bucket

    router = new express.Router()

    router.param('modelId', (req, res, next, modelId)->
        db.get(bucket, modelId, {}, (err, object, meta)->
            if err then return next(err)
            res.locals.model = object
            res.locals.meta = meta
            next()
        )
    )

    router.get('/', (req, res, next)->
        db.query(bucket, req.query, (err, keys, meta)->
            if err then return next(err)

            res.format({
                json: ->
                    async.map(keys, (key, callback)->
                        db.get('activities', key, {}, (err, object, meta)->
                            callback(err, object)
                        )
                    , (err, results)->
                        if err then return next(err)
                        res.json(results)
                    )
                html: ->
                    modelCtor.prototype.fetch = (options)->
                        db.get('activities', @id, {}, (err, object, meta)=>
                            if err then return options.error?(err)
                            @set(object)
                            options.success?()
                        )
                    collection = new Backbone.Collection([], {
                        model: modelCtor
                        url: req.originalUrl.replace(/\?.*$/, '')
                    })
                    collection.query = req.originalUrl.replace(/^[^\?]*/,'')

                    for key in keys
                        model = new modelCtor()
                        model.id = key
                        model.needsData = true
                        collection.add(model)

                    res.writeContinue()
                    res.render(modelProto.defaultListView, {
                        itemView: modelProto.defaultView
                        collection: collection
                    })
            })
        )
    )

    router.get('/:modelId.:format?', (req, res, next)->
        res.format({
            json: ->
                res.json(res.locals.model)
            html: ->
                model = new modelCtor(res.locals.model)
                res.render(modelProto.defaultView, {model: model})
        })
    )

    return router.middleware



# Backbone = require("backbone")
# app.get('/', (req, res, next)->
#     db.query('activities', {city: "Paris"}, (err, keys, meta)->
#         if err then return next(err)
#         c = new Backbone.Collection()

#         async.map(keys, (key, callback)->
#             db.get('activities', key, {}, (err, object, meta)->
#                 callback(err, object)
#             )
#         , (err, results)->
#             if err then return next(err)
#             c = new Backbone.Collection(results)
#             c.url = "/activities_by_city/Paris"

#             res.render('activities', {
#                 collection: c
#             })
#         )

#     )
#     # res.render('generic', {title: "Homepage - #{app.get('appName')}"})
# )
