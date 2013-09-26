# # resource.coffee
# ### [Cosmo's Middleware Factory](http://www.youtube.com/watch?v=lIPan-rEQJA)

# *This file instantiates a [riak](http://basho.com/riak/) db and then builds a middleware stack for 
# [REST](http://en.wikipedia.org/wiki/Representational_state_transfer) operations that might be commonly performed on it.*
# ***

# Load the [`express` node module](http://expressjs.com/)
express = require('express')
# Load the [`async` node module](https://github.com/caolan/async)
async = require('async')
# Load the [`riak-js` node module](http://riakjs.com/)
riak = require("riak-js")
# Set the `servers` variable based on the number IDed in the `environment`
servers = process.env.RIAK_SERVERS.split(/,/)

# Instantiate a riak db with `servers` number of servers
db = riak.getClient({pool:{servers: servers, options: {}}})

# Load the [`lodash` node module](http://lodash.com/) globally so that the models that get loaded by the function below
# have access to it. Lodash ~= Underscore, with better performance.
global._ = require('lodash')

# Load the [`backbone` node module](http://backbonejs.org/) globally so that the models that get loaded by the function
# below have access to it
global.Backbone = require('backbone')

# #### Middleware factory

# Exports a function that maps a backbone model to express middleware that handles standard REST operations
module.exports = (options = {})->
    # Inherits relevant variables from the model the function is called with
    modelCtor = options.model
    modelName = modelCtor.name
    modelProto = modelCtor.prototype
    bucket = options.bucket ? modelProto.bucket
    itemView = options.itemView ? modelProto.defaultView
    listView = options.listView ? modelProto.defaultListView
    

    # Sets up a new express router with the following substack:
    router = new express.Router()

    # * Provides a function to look up an object on the riak server by modelID(?)
    router.param('modelId', (req, res, next, modelId)->
        db.get(bucket, modelId, {}, (err, object, meta)->
            if err then return next(err)
            res.locals.model = object
            res.locals.meta = meta
            next()
        )
    )

    # * Provides a default route for the base url of the model to GET objects by passing in a query, or all objects if
    # no query is present, and return either a JSON representation or a rendered page, depending
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
                    # note that this, and all other `res.render()` functions, employ 
                    # [DUST-RENDERER.COFFEE](dust-renderer.html) to override the default rendering function
                    res.render(listView, {
                        itemView: itemView
                        collection: collection
                    })
            })
        )
    )

    # * Provides a route that GETs either a JSON representation, or the `itemView`, of the passed-in model by ID.
    router.get('/:modelId.:format?', (req, res, next)->
        res.format({
            json: ->
                res.json(res.locals.model)
            html: ->
                model = new modelCtor(res.locals.model)
                res.render(itemView, {model: model})
        })
    )

    # * Provides a route to instantiate an object in the riak DB.
    router.post('/', (req, res, next)->
        db.save(bucket, null, req.body, {returnbody: true, index: {group: 'all'}}, (err, object, meta)->
            if (err)
                return next(err)
            else
                object.id = meta.key
                res.set({
                    'ETag' : meta.etag,
                    'last-modified' : meta.lastMod
                })
                res.status(meta.statusCode)
                return res.json(object)
        )
    )

    # * Provides a route to fully update (PUT) an object by the appropriate `modelID` in the riak DB
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

    # * Provides a route to partially update (PATCH) an object by the appropriate `modelID` in the riak DB
    router.patch('/:modelId', (req, res, next)->
        for key, val of req.body
            res.locals.model[key] = val

# Backbone = require("backbone")
# app.get('/', (req, res, next)->
#     db.query('activities', {city: "Paris"}, (err, keys, meta)->
#         if err then return next(err)
#         c = new Backbone.Collection()

    # * Provides a route to DELETE an object by the appropriate `modelID` in the riak DB
    router.delete('/:modelId', (req, res, next)->
        db.remove(bucket, req.params.modelId, (err, object, meta)->
            if (err)
                return next(err)
            else
                res.status(204)
                res.end()
        )
    )

#             res.render('activities', {
#                 collection: c
#             })
#         )

    return router.middleware

# ***
# ***NEXT**: Step into [DUST-RENDERER.COFFEE](dust-renderer.html) and observe how it overrides the current 
# `res.render()` function, or step into [ERROR-HANDLER.COFFEE](error-handler.html) and see how it is designed to 
# process errors.*
