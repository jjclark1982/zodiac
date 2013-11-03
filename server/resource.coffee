# # resource.coffee
# ### [Cosmo's Middleware Factory](http://www.youtube.com/watch?v=lIPan-rEQJA)

# *This file instantiates a [riak](http://basho.com/riak/) db and then builds a middleware stack for 
# [REST](http://en.wikipedia.org/wiki/Representational_state_transfer) operations that might be commonly performed on it.*
# ***

express = require('express')
async = require('async')
db = require("./db")

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
    
    renderItem = (res, item)->
        meta = res.locals.meta
        res.set({
            'ETag': meta.etag,
            'last-modified': meta.lastMod
        }) if meta
        #todo: cache control even if meta is not set as expected
        #todo: check if req matches cache and return 304
        for name, value of meta._headers when name.match(/^x-riak/)
            res.set(name, value)

        item._vclock = res.locals.meta.vclock

        res.format({
            json: ->
                res.json(item)
            html: ->
                res.render(itemView, {model: new modelCtor(item)})
        })

    # Sets up a new express router with the following substack:
    router = new express.Router()

    # * Provides a function to look up an object on the riak server by modelID(?)
    router.param('modelId', (req, res, next, modelId)->
        db.get(bucket, modelId, {}, (err, object, meta)->
            if err then return next(err)
            object[modelProto.idAttribute or 'id'] = modelId
            res.locals.model = object
            res.locals.meta = meta
            next()
        )
    )

    # * Provides a default route for the base url of the model to GET objects by passing in a query, or all objects if
    # no query is present, and return either a JSON representation or a rendered page, depending
    router.get('/', (req, res, next)->
        callback = (err, keys, meta)->
            if err then return next(err)

            res.format({
                json: ->
                    async.map(keys, (key, callback)->
                        #TODO: pass through req.headers for things like cache-control
                        db.get(bucket, key, {}, (err, object, meta)->
                            object[modelProto.idAttribute or 'id'] = key
                            object._vclock = meta.vclock
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
                                    db.get(bucket, @id, {}, (err, object, meta)=>
                                        if err then return options.error?(err)
                                        @set(object)
                                        options.success?()
                                    )
                                )
                        collection.add(model)

                    # note that this, and all other `res.render()` functions, employ 
                    # [DUST-RENDERER.COFFEE](dust-renderer.html) to override the default rendering function
                    res.render(listView, {
                        itemView: itemView
                        collection: collection
                    })
            })
        if Object.keys(req.query).length > 0
            db.query(bucket, req.query, callback)
        else
            #TODO: refactor this with above
            #TODO: rate-limiting
            res.format({
                json: ->
                    db.getAll(bucket, {}, (err, objects, meta)->
                        if err then return next(err)
                        res.json(objects)
                    )
                html: ->
                    #TODO: support needsData for collections
                    collection = new Backbone.Collection([], {
                        model: modelCtor
                        url: req.originalUrl
                    })

                    db.keys(bucket, {keys: 'stream'}, (err, keys, meta)->
                        if err then return next(err)

                        res.render(listView, {
                            itemView: itemView
                            collection: collection
                        })
                    ).on('keys', (keys=[])->
                        #TODO: support needsData
                        for key in keys
                            model = new modelCtor()
                            model.id = key
                        collection.add(model)

                    ).start()
            })
    )

    # * Provides a route that GETs either a JSON representation, or the `itemView`, of the passed-in model by ID.
    #TODO: handle multiple options
    router.get('/:modelId.:format?', (req, res, next)->
        renderItem(res, res.locals.model)
    )

    # * Provides a route to instantiate an object in the riak DB.
    router.post('/', (req, res, next)->
        model = new modelCtor(req.body)
        # run the backbone validator
        unless model.isValid()
            res.status(403)
            return next(new Error(model.validationError))

        meta = {returnbody: true}
        db.save(bucket, null, model.toJSON(), meta, (err, object, meta)->
            res.status(meta.statusCode)
            if (err)
                return next(err)
            else
                object[modelProto.idAttribute or 'id'] = meta.key
                renderItem(res, object)
        )
    )

    # * Provides a route to fully update (PUT) an object by the appropriate `modelID` in the riak DB
    router.put('/:modelId', (req, res, next)->
        if req.body?.vclock
            res.locals.meta.vclock = req.body.vclock
        delete req.body._vclock

        model = new modelCtor(res.locals.model)
        model.attributes = req.body # set all attributes
        model.id = req.params.modelId # don't support renaming for now
        # run the backbone validator
        unless model.isValid()
            res.status(403)
            return next(new Error(model.validationError))

        meta = {}
        meta.returnbody = true
        meta.vclock = res.locals.meta.vclock
        if model.index
            meta.index = _.result(model, 'index')

        db.save(bucket, req.params.modelId, model.toJSON(), meta, (err, object, meta)->
            if (err)
                return next(err)
            else
                res.locals.meta = meta
                res.status(meta.statusCode)
                renderItem(res, object)
        )
    )

    # * Provides a route to partially update (PATCH) an object by the appropriate `modelID` in the riak DB
    router.patch('/:modelId', (req, res, next)->
        if req.body?.vclock
            res.locals.meta.vclock = req.body.vclock
        delete req.body._vclock

        model = new modelCtor(res.locals.model)
        model.set(req.body) # set only transmitted attributes
        model.id = req.params.modelId
        # run the backbone validator
        unless model.isValid()
            res.status(403)
            return next(new Error(model.validationError))

        meta = {}
        meta.returnbody = true
        if model.index
            meta.index = _.result(model, 'index')

        db.save(bucket, req.params.modelId, model.toJSON(), meta, (err, object, meta)->
            if (err)
                return next(err)
            else
                res.locals.meta = meta
                res.status(meta.statusCode)
                renderItem(res, object)
        )
    )

    # * Provides a route to DELETE an object by the appropriate `modelID` in the riak DB
    router.delete('/:modelId', (req, res, next)->
        db.remove(bucket, req.params.modelId, (err, object, meta)->
            if (err)
                return next(err)
            else
                res.location(modelProto.urlRoot)
                res.status(204)
                res.end()
        )
    )


    return router.middleware

# ***
# ***NEXT**: Step into [DUST-RENDERER.COFFEE](dust-renderer.html) and observe how it overrides the current 
# `res.render()` function, or step into [ERROR-HANDLER.COFFEE](error-handler.html) and see how it is designed to 
# process errors.*
