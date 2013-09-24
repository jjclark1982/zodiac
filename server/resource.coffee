# load the [`express` node module](http://expressjs.com/)
express = require('express')
# load the [`async` node module](https://github.com/caolan/async)
async = require('async')
# load the [`riak-js` node module](http://riakjs.com/)
riak = require("riak-js")
# set the servers variable based on the number IDed in the `.env` variable
servers = process.env.RIAK_SERVERS.split(/,/)

# instantiate a riak db with `servers` number of servers
db = riak.getClient({pool:{servers: servers, options: {}}})

# load the [`lodash` node module](http://lodash.com/) globally so that the models that get loaded by the function below
# have access to it. Lodash ~= Underscore, with better performance.
global._ = require('lodash')

# load the [`backbone` node module](http://backbonejs.org/) globally so that the models that get loaded by the function
#below have access to it
global.Backbone = require('backbone')

# #### Middleware factory

# exports a function that maps a backbone model to express middleware that handles standard REST operations
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
                        #TODO: pass through req.headers for things like cache-control
                        db.get(bucket, key, {}, (err, object, meta)->
                            callback(err, object)
                        )
                    , (err, results)->
                        if err then return next(err)
                        res.json(results)
                    )
                html: ->
                    # modelCtor.prototype.fetch = 
                    collection = new Backbone.Collection([], {
                        model: modelCtor
                        url: req.originalUrl.replace(/\?.*$/, '')
                    })
                    collection.query = req.originalUrl.replace(/^[^\?]*/,'')

                    for key, i in keys then do (key,i)->
                        model = new modelCtor()
                        model.id = key
                        if i < 5
                            model.needsData = true
                            model.fetch = (options)->
                                process.nextTick(=>
                                    db.get('activities', @id, {}, (err, object, meta)=>
                                        if err then return options.error?(err)
                                        @set(object)
                                        options.success?()
                                    )
                                )
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

    router.put('/:modelId', (req, res, next)->
        #TODO: re-run validator on res.locals.model
        db.save(bucket, req.body.id, req.body, {returnbody: true}, (err, object, meta)->
            if (err)
                return next(err)
            else
                res.set({
                    'ETag' : meta.etag,
                    'last-modified' : meta.lastMod
                })
                res.status(meta.statusCode)
                return res.json(object)
        )
    )


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
