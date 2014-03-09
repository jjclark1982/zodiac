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

saveModel = (req, res, next, model, options={})->
    vclock = req.body?._vclock or req.model?.vclock
    delete req.body._vclock

    # support setting the id of a new object by data or endpoint
    modelId = req.params.modelId or model.id
    model[model.idAttribute] = modelId

    # run the backbone validator
    unless model.isValid()
        res.status(403)
        return next(new Error(model.validationError))

    # save it if it passed validation
    model.save().then(->
        if !req.model
            res.status(201) # created

            # when creating by POST, redirect from the urlRoot to the new model's url
            if req.method is "POST"
                return res.redirect(303, model.url())

        sendModel(req, res, next, model)

    , (error)->
            if options.statusCode
                res.status(options.statusCode)
            next(error)
    )

sendModel = (req, res, next, model)->
    res.set({
        'Last-Modified': model.lastMod
        'Vary': 'Accept,Accept-Encoding'
        'Link': "<#{model.urlRoot}>; rel=\"up\""
        'Location': model.url()
    })
    for name, value of model.metadataFromRiak._headers when name.match(/^x-riak/i)
        res.set(name, value)

    res.format({
        json: ->
            res.set({'ETag': model.etag})
        html: ->
            res.set({'ETag': model.etag+'h'})
    })

    # now that last-modified, vary, and etag are set,
    # we can send a "not modified" response to clients a fresh cache
    if req.fresh
        return res.send(304)

    # if the entity is not cached, send it in the requested format
    res.format({
        json: ->
            item = model.toJSON()
            item._vclock = model.vclock
            res.json(item)
        html: ->
            res.render(model.defaultView, {
                model: model
                title: (_.result(model, 'title') or '')
            })
        })

sendList = (req, res, next, collection)->
    idAttribute = collection.model.prototype.idAttribute
    listView = collection.model.prototype.defaultListView

    res.format({
        json: ->
            async.map(collection.models, (model, callback)->
                model.fetch().then(->
                    model.attributes._vclock = model.vclock
                    callback(null, model)
                , callback)
            , (err, models)->
                if err then return next(err)
                res.json(collection)
                #TODO: pass through req.headers for things like cache-control
                #TODO: support streaming by iterating through fetch promises
            )
        html: ->
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
    idAttribute = modelProto.idAttribute or 'id'

    # Sets up a new express router with the following substack:
    router = new express.Router()

    # * Provides a function to look up an object on the riak server by modelID(?)
    router.param('modelId', (req, res, next, modelId)->
        model = new modelCtor()
        model.id = modelId
        model.fetch().then(->
            req.model = model
            next()

        , (err)->
            if err.statusCode is 404
                # This model doesn't exist yet. Let method handlers decide what to do.
                req.model = null
                next()
            else
                next(err)
        )
    )

    # * Provides a default route for the base url of the model to GET objects by passing in a query, or all objects if
    # no query is present, and return either a JSON representation or a rendered page, depending
    router.get('/', (req, res, next)->
        collection = new Backbone.Collection([], {model: modelCtor})
        collection.url = modelProto.urlRoot
        if Object.keys(req.query).length > 0
            collection.query = req.query

        collection.fetch().then(->
            sendList(req, res, next, collection)
        , next)
    )

    # * Provides a route that GETs either a JSON representation, or the `itemView`, of the passed-in model by ID.
    #TODO: handle multiple options in case of editing conflict
    router.get('/:modelId.:format?', (req, res, next)->
        if !req.model then return next(404)

        sendModel(req, res, next, req.model)
    )

    # * Provides a route to instantiate an object in the riak DB.
    router.post('/', (req, res, next)->
        model = new modelCtor(req.body)
        saveModel(req, res, next, model, {create: true})
    )

    # * Provides a route to fully update (PUT) an object by the appropriate `modelID` in the riak DB
    router.put('/:modelId', (req, res, next)->
        if req.model
            model = req.model
            model.attributes = req.body
            model.set(model.attributes)
        else
            # allow creation by PUT
            model = new modelCtor(req.body)

        saveModel(req, res, next, model)
    )

    # * Provides a route to partially update (PATCH) an object by the appropriate `modelID` in the riak DB
    router.patch('/:modelId', (req, res, next)->
        if !req.model then return next(404)

        model = req.model
        model.set(req.body)
        saveModel(req, res, next, model)
    )

    # * Provides a route to DELETE an object by the appropriate `modelID` in the riak DB
    router.delete('/:modelId', (req, res, next)->
        if !req.model then return next(404)

        req.model.destroy().then(->
            res.location(model.urlRoot)
            res.status(204)
            res.end()
        , next)
    )

    router.get("/:modelId/versions", (req, res, next)->
        # in order to access versions of a model:
        # we have to set the bucket policy to something other than LWW
        # pick the most relevant sibling in most cases
        # and send all siblings in this case
        next(501)
    )

    # links are similar to indexes
    # they get stored by id in the data object itself
    # and the data gets transformed into metadata on save
    # then we can load the link by its id 
    # or we can use link-walking to skip the `modelId` handler for faster reads

    for linkName, linkDef of modelProto.links or {} then do (linkName, linkDef)->
        TargetCtor = require("models/"+linkDef.target)
        targetProto = TargetCtor.prototype

        router.get("/:modelId/#{linkName}", (req, res, next)->
            parent = req.model
            childId = parent.get("_links")?[linkName]
            if !childId then return next(404)

            child = new TargetCtor()
            child.id = childId
            child.fetch().then(->
                sendModel(req, res, next, child)
            , next)
        )

        router.post("/:modelId/#{linkName}", (req, res, next)->
            if linkDef.type isnt 'hasOne'
                # TODO: handle multiple children when link-walking returns 300
                return next(501)

            child = new TargetCtor(req.body)
            child.save().then(->
                parent = req.model
                links = _.clone(parent.get("_links")) or {}
                links[linkName] = child.id
                # TODO: check whether we are overwriting anything
                # and then delete, merge, create siblings, or return 409
                parent.save({_links: links}).then(->
                    sendModel(req, res, next, child)
                , (err)->
                    # updating the parent failed during validation or write
                    # destroy the orphaned child and report the error condition
                    child.destroy()
                    next(err)
                )
            , next)
            return
        )

        router.delete("/:modelId/#{linkName}", (req, res, next)->
            parent = req.model
            childId = parent.get("_links")?[linkName]
            if !childId then return next(404)
        )

        router.put("/:modelId/#{linkName}", (req, res, next)->
            next(501)
        )

        router.patch("/:modelId/#{linkName}", (req, res, next)->
            next(501)
        )

    return router.middleware

# ***
# ***NEXT**: Step into [DUST-RENDERER.COFFEE](dust-renderer.html) and observe how it overrides the current
# `res.render()` function, or step into [ERROR-HANDLER.COFFEE](error-handler.html) and see how it is designed to
# process errors.*
