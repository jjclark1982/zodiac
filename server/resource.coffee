# # resource.coffee
# ### [Cosmo's Middleware Factory](http://www.youtube.com/watch?v=lIPan-rEQJA)

# *This file instantiates a [riak](http://basho.com/riak/) db and then builds a middleware stack for
# [REST](http://en.wikipedia.org/wiki/Representational_state_transfer) operations that might be commonly performed on it.*
# ***

express = require('express')
async = require('async')
db = require("./db")

# define the server-side global Backbone that syncs to Riak
require("./backbone-sync-riak")

# #### Middleware factory
# this is an express backbone resource handler
# it mounts a given modelProto at its declared urlRoot
# and stands between the frontend and the backend, enforcing validation
# it should express most actions in terms of
# model.fetch(), model.save(), and res.render()
# and let the backbone-db mapper implement the sync() calls

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
        model = res.locals.model
        meta = res.locals.meta or {}

        # support "not modified" responses
        res.set({
            'Last-Modified': model.lastMod
            'Vary': 'Accept,Accept-Encoding'
            'Link': "<#{model.urlRoot}>; rel=\"up\""
            'Location': model.url()
        })
        for name, value of meta._headers when name.match(/^x-riak/i)
            res.set(name, value)

        res.format({
            json: ->
                res.set({'ETag': model.etag})
            html: ->
                res.set({'ETag': model.etag+'h'})
        })

        if req.fresh
            return res.send(304)

        item._vclock = meta.vclock

        res.format({
            json: ->
                item = model.toJSON()
                item._vclock = model.vclock
                res.json(item)
            html: ->
                res.render(itemView, {
                    model: model
                    title: (_.result(model, 'title') or '')
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
                # redirect to a resource that was created without a full URL
                if req.method is "POST"
                    res.redirect(303, modelProto.urlRoot + '/' + meta.key)
                    return
                else
                    res.status(201)

            renderItem(req, res, next, object)
        )


    # Sets up a new express router with the following substack:
    router = new express.Router()

    # * Provides a function to look up an object on the riak server by modelID(?)
    router.param('modelId', (req, res, next, modelId)->
        model = new modelCtor()
        model.id = modelId
        model.fetch({
            success: (model, response, options)->
                res.locals.model = model
                res.locals.meta = options.meta # TODO: find a better solution
                next()
            error: (model, err, options)->
                if err.statusCode is 404
                    # This model doesn't exist yet. Let method handlers decide what to do.
                    res.locals.model = null
                    next()
                else
                    next(err)
        })
    )

    # * Provides a default route for the base url of the model to GET objects by passing in a query, or all objects if
    # no query is present, and return either a JSON representation or a rendered page, depending
    router.get('/', (req, res, next)->
        if Object.keys(req.query).length > 0
            # run a query
            console.log("original url:",req.originalUrl)
            res.locals.collection = new Backbone.Collection([], {
                model: modelProto
                url: modelProto.urlRoot
                query: req.query
            })
            db.query(bucket, req.query, (err, keys, meta)->
                if err then return next(err)
                renderList(req, res, next, keys)
            )
        else
            # no query specified. list all if allowed
            # TODO: use {all: '1'} fallback query instead of streaming
            if not modelProto.allowListAll
                return next(503)
            allKeys = []
            db.keys(bucket, {keys: 'stream'}, (err, keys, meta)->
                if err then return next(err)
                renderList(req, res, next, allKeys)
            ).on('keys', (keys=[])->
                for key in keys
                    allKeys.push(key)
            ).start()
    )

    # * Provides a route that GETs either a JSON representation, or the `itemView`, of the passed-in model by ID.
    #TODO: handle multiple options in case of editing conflict
    router.get('/:modelId.:format?', (req, res, next)->
        unless res.locals.model
            return next(404)

        renderItem(req, res, next, res.locals.model)
    )

    # * Provides a route to instantiate an object in the riak DB.
    router.post('/', (req, res, next)->
        saveItem(req, res, next, {create: true})
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
        unless res.locals.model
            return next(404)

        res.model.destroy({
            error: (model, err, options)->
                next(err)
            success: (model, response, options)->
                res.location(modelProto.urlRoot)
                res.status(204)
                res.end()
        })
    )

    router.get("/:modelId/versions", (req, res, next)->
        #TBD
        next()
    )

    for linkName, linkDef of modelProto.links or {}
        target = require("models/"+linkDef.target)
        targetProto = target.prototype

        router.post("/:modelId/#{linkName}", (req, res, next)->
            console.log(req.body)
            # create the object or overwrite it, i don't know
            #
            # posting to a cart is weird because we are adding to an item, not to a collection
            # would like to check in console whether multiple links work
            # yes, we just have to interpret the multiple option result on read
            res.render(targetProto.defaultView)
        )
        router.get("/:modelId/#{linkName}", (req, res, next)->
            # res.json(linkDef)
            # show the linked item(s) with their natural views
            res.render(targetProto.defaultView)
        )
        # in any case, we need to preserve links much the same way we are preserving indexes

    return router.middleware

# ***
# ***NEXT**: Step into [DUST-RENDERER.COFFEE](dust-renderer.html) and observe how it overrides the current
# `res.render()` function, or step into [ERROR-HANDLER.COFFEE](error-handler.html) and see how it is designed to
# process errors.*
