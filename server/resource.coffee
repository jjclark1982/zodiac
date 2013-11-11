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
module.exports = (moduleOptions = {})->
    # Inherits relevant variables from the model the function is called with
    modelCtor = moduleOptions.model
    modelName = modelCtor.name
    modelProto = modelCtor.prototype
    bucket = moduleOptions.bucket ? modelProto.bucket
    itemView = moduleOptions.itemView ? modelProto.defaultView
    listView = moduleOptions.listView ? modelProto.defaultListView
    idAttribute = modelProto.idAttribute or 'id'

    renderItem = (req, res, next, item)->
        meta = res.locals.meta or {}

        # support "not modified" responses
        # note that 
        res.set({
            'ETag': meta.etag,
            'Last-Modified': meta.lastMod
            'Vary': 'Accept,Accept-Encoding'
            'Location': modelProto.urlRoot + '/' + meta.key
        })
        for name, value of meta._headers when name.match(/^x-riak/i)
            res.set(name, value)
        #TODO: translate "Link" header
        #TODO: consider redirecting if originalUrl doesn't match Location

        item._vclock = meta.vclock

        res.format({
            json: ->
                if req.fresh then return res.end(304)
                res.json(item)
            html: ->
                res.set({'ETag': meta.etag + "h"})
                if req.fresh then return res.end(304)

                # TODO: see if title can be set in a more coherent way
                try
                    ItemView = require('views/'+itemView)
                    view = new ItemView({model: new modelCtor(item)})
                    title = _.result(view, 'title') or ''
                catch e
                    null
                res.render(itemView, {
                    model: new modelCtor(item)
                    title: title
                })
        })

    renderList = (req, res, next, keys)->
        res.format({
            json: ->
                async.map(keys, (key, callback)->
                    #TODO: pass through req.headers for things like cache-control
                    db.get(bucket, key, {}, (err, object, meta)->
                        object[idAttribute] = key
                        object._vclock = meta.vclock
                        callback(err, object)
                    )
                , (err, results)->
                    if err then return next(err)
                    res.json(results)
                )
            html: ->
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

                try
                    title = _.result(require('views/'+listView).prototype, 'title') or ''
                catch e
                    null
                res.render(listView, {
                    collection: collection
                    title: title
                })
        })

    saveItem = (req, res, next, options={})->
        vclock = req.body?._vclock or res.locals.meta?.vclock
        delete req.body._vclock

        model = new modelCtor(res.locals.object)
        if options.merge
             # set only the transmitted attributes
            model.set(req.body)
            delete options.merge
        else
            # set all attributes
            model.attributes = req.body
            model.set(model.attributes)

        # support setting the id of a new object
        modelId = req.params.modelId or model.id
        model.id = modelId

        # run the backbone validator
        unless model.isValid()
            res.status(403)
            return next(new Error(model.validationError))

        options.returnbody = true
        options.vclock = vclock
        if model.index
            options.index = _.result(model, 'index')

        db.save(bucket, modelId, model.toJSON(), options, (err, object, meta)->
            res.status(meta.statusCode)
            if (err) then return next(err)

            res.locals.meta = meta
            object[idAttribute] = meta.key

            if options.create
                res.redirect(modelProto.urlRoot + '/' + meta.key)
            else
                renderItem(req, res, next, object)
        )


    # Sets up a new express router with the following substack:
    router = new express.Router()

    # * Provides a function to look up an object on the riak server by modelID(?)
    router.param('modelId', (req, res, next, modelId)->
        db.get(bucket, modelId, {}, (err, object, meta)->
            if err then return next(err)
            object[idAttribute] = modelId
            res.locals.object = object
            res.locals.meta = meta
            next()
        )
    )

    # * Provides a default route for the base url of the model to GET objects by passing in a query, or all objects if
    # no query is present, and return either a JSON representation or a rendered page, depending
    router.get('/', (req, res, next)->
        if Object.keys(req.query).length > 0
            db.query(bucket, req.query, (err, keys, meta)->
                if err then return next(err)
                renderList(req, res, next, keys)
            )
        else
            return next(503)
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
    #TODO: handle multiple options in case of editing conflict
    router.get('/:modelId.:format?', (req, res, next)->
        renderItem(req, res, next, res.locals.object)
    )

    # * Provides a route to instantiate an object in the riak DB.
    router.post('/', (req, res, next)->
        saveItem(req, res, next, {create: true})
        #TODO: investigate whether we need to set "location" header
    )

    # * Provides a route to fully update (PUT) an object by the appropriate `modelID` in the riak DB
    router.put('/:modelId', (req, res, next)->
        saveItem(req, res, next)
    )

    # * Provides a route to partially update (PATCH) an object by the appropriate `modelID` in the riak DB
    router.patch('/:modelId', (req, res, next)->
        saveItem(req, res, next, {merge: true})
    )

    # * Provides a route to DELETE an object by the appropriate `modelID` in the riak DB
    router.delete('/:modelId', (req, res, next)->
        db.remove(bucket, req.params.modelId, (err, object, meta)->
            if (err) then return next(err)

            res.location(modelProto.urlRoot)
            res.status(204)
            res.end()
        )
    )

    router.get("/:modelId/versions", (req, res, next)->
        #TBD
        next()
    )

    for linkName, linkDef of modelProto.links or {}
        router.get("/:modelId/#{linkName}", (req, res, next)->
            res.json(linkDef)
            #TOOD: show the linked item(s) with their natural views
        )
        # TODO: support POST/DELETE to edit links

    return router.middleware

# ***
# ***NEXT**: Step into [DUST-RENDERER.COFFEE](dust-renderer.html) and observe how it overrides the current 
# `res.render()` function, or step into [ERROR-HANDLER.COFFEE](error-handler.html) and see how it is designed to 
# process errors.*
