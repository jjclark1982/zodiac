# # resource.coffee

# *This file implements a middleware handler with
# [REST](http://en.wikipedia.org/wiki/Representational_state_transfer) endpoints
# for a a given model type.*

express = require('express')
async = require('async')

# define the server-side global Backbone that syncs to Riak
require("./backbone-sync-riak")

saveModel = (req, res, next, model, options={})->
    model.vclock = req.get("X-Riak-Vclock")

    isValid = model.save({}, {
        wait: true
        editor: req.user
        success: ->
            if options.create
                res.status(201) # created

                # when creating by POST, redirect from the urlRoot to the new model's url
                if req.method is "POST"
                    return res.redirect(303, model.url())

            sendModel(req, res, next, model)
        error: (error)->
            next(error)
    })

    unless isValid
        res.status(403)
        return next(new Error(model.validationError))

sendModel = (req, res, next, model)->
    format = req.params.format or req.accepts(['json', 'html'])
    unless format in ['json', 'html']
        return next(406)

    res.location(model.url())
    links = {
        up: model.urlRoot
    }
    for linkName, target of model.linkedModels() or {}
        if target
            links[linkName] = _.result(target, 'url')
    res.links(links)

    res.set({
        'Last-Modified': model.lastMod
        'Vary': "Accept" # TODO: make sure this doesn't overwrite anything important
        'X-DB-Query-Time': new Date() - res.dbStartTime
    })
    # the ETag of the html is not known before rendering because the template may have changed
    # TODO: support sending it as a trailer
    if format is 'json'
        res.set({"ETag": model.etag})
    for name, value of model.metadataFromRiak._headers when name.match(/^x-/i)
        res.set(name, value)

    # now that last-modified, vary, and etag are set,
    # we can send a "not modified" response to clients with a fresh cache.
    # this may be useful for filling in metadata for a bootstrapped data-only model
    if req.fresh
        return res.send(304)

    # if the entity is not cached, send it in the requested format
    switch format
        when 'json'
            item = model.toJSON()
            res.json(item)
        when 'html'
            res.type("html") # set this before streaming begins so that gzip can kick in
            view = req.query?.view or req.view or model.defaultView
            res.render(view, {
                model: model
                title: (_.result(model, 'title') or '')
            })

sendList = (req, res, next, collection)->
    idAttribute = collection.model.prototype.idAttribute

    res.set({
        'Vary': 'Accept,Accept-Encoding'
        'Location': collection.url
        'X-DB-Query-Time': new Date() - res.dbStartTime
    })

    format = req.params.format or req.accepts(['json', 'html'])
    unless format in ['json', 'html']
        return next(406)
    switch format
        when 'json'
            vclocks = {}
            async.map(collection.models, (model, callback)->
                model.fetch().then(->
                    vclocks[model.id] = model.vclock
                    callback(null, model)
                , (fetchErr)->
                    if fetchErr.statusCode is 404
                        collection.remove(model, {silent: true})
                        callback()
                    else
                        callback(fetchErr)
                )
            , (err, models)->
                if err then return next(err)
                res.set({'X-DB-Query-Time': new Date() - res.dbStartTime})
                res.set({"X-Riak-Vclocks": JSON.stringify(vclocks)})
                lastMod = null
                for model in collection.models
                    lastMod = model.lastMod unless lastMod > model.lastMod
                res.set({'Last-Modified': lastMod})
                if req.fresh
                    return res.send(304)
                res.json(collection)
                #TODO: pass through req.headers for things like cache-control
                #TODO: support streaming by iterating through fetch promises
                # then we would no longer depend on async
            )
        when 'html'
            res.type("html") # set this before streaming begins so that gzip can kick in

            # mark models to have their data fetched during rendering
            for model in collection.models
                model.needsData = true

            # note that this, and all other `res.render()` functions, employ
            # [DUST-RENDERER.COFFEE](dust-renderer.html) to override the default rendering function
            view = req.query?.view or req.view or collection.model.prototype.defaultListView
            res.render(view, {
                collection: collection
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

    # * Look up an object in the database by its id
    router.param('modelId', (req, res, next, modelId)->
        res.dbStartTime = new Date()

        if modelId is 'random'
            # Redirect to a random item of this type (read-only)
            return next(405) unless req.method in ["GET", "HEAD", "OPTIONS"]
            collection = new Backbone.Collection([], {model: modelCtor})
            collection.fetch().then(->
                res.set({'X-DB-Query-Time': new Date() - res.dbStartTime})
                if collection.length is 0
                    return next(404)
                randomIndex = Math.floor(Math.random()*collection.length)
                randomId = collection.at(randomIndex)?.id or ''
                newUrl = req.originalUrl.replace(/\/random/, '/'+randomId)
                res.redirect(302, newUrl)
            , (err)->
                next(err)
            )
            return

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
    router.get('/.:format?', (req, res, next)->
        res.dbStartTime = new Date()
        collection = new Backbone.Collection([], {model: modelCtor})
        collection.url = modelProto.urlRoot
        if Object.keys(req.query).length > 0
            collection.query = req.query

        collection.fetch({query: req.query}).then(->
            sendList(req, res, next, collection)
        , (err)->
            next(err)
        )
    )

    # * Provides a route that GETs either a JSON representation, or the `itemView`, of the passed-in model by ID.
    #TODO: handle multiple options in case of editing conflict
    router.get('/:modelId-:slug.:format?', (req, res, next)->
        if !req.model then return next(404)

        sendModel(req, res, next, req.model)
    )
    router.get('/:modelId.:format?', (req, res, next)->
        if !req.model then return next(404)

        sendModel(req, res, next, req.model)
    )

    # * Provides a route to instantiate an object in the riak DB.
    router.post('/', (req, res, next)->
        model = new modelCtor(req.body)
        if model.isNew()
            saveModel(req, res, next, model, {create: true})

        else
            # allow specifying initial id, unless it is already taken
            model.fetch().then(->
                res.status(409)
                next(new Error("#{idAttribute} '#{model.id}' is already taken"))
            , (err)->
                if err.statusCode is 404
                    saveModel(req, res, next, model, {create: true})
                else
                    next(err)
            )
    )

    # * Provides a route to fully update (PUT) an object by the appropriate `modelID` in the riak DB
    router.put('/:modelId', (req, res, next)->
        options = {}
        if req.model
            model = req.model
            # model.attributes = req.body
            model.set(req.body, {validate: false})
        else
            # allow creation by PUT
            model = new modelCtor(req.body)
            options.create = true

        saveModel(req, res, next, model, options)
    )

    # * Provides a route to partially update (PATCH) an object by the appropriate `modelID` in the riak DB
    router.patch('/:modelId', (req, res, next)->
        if !req.model then return next(404)

        model = req.model
        model.set(req.body, {editor: req.user})
        saveModel(req, res, next, model)
    )

    # * Provides a route to DELETE an object by the appropriate `modelID` in the riak DB
    router.delete('/:modelId', (req, res, next)->
        if !req.model then return next(404)

        req.model.destroy().then(->
            res.location(req.model.urlRoot)
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

    router.param("linkName", (req, res, next, linkName)->
        linkDef = modelProto.fieldDefs()[linkName]

        if linkDef?.type isnt "link"
            return next(404)

        req.linkDef = linkDef
        parent = req.model
        child = parent.getLink(linkName)
        if !child
            req.linkTarget = null
            return next()

        if linkDef.multiple
            req.linkTarget = child
            # at this point it's a skeleton collection
            return next()

        else
            child.fetch().then(->
                req.linkTarget = child
                next()

            , (err)->
                if err.statusCode is 404
                    # TODO: update the parent data to reflect the missing child?
                    req.linkTarget = null
                    next()
                else
                    next(err)
            )
    )

    router.get("/:modelId/:linkName", (req, res, next)->
        if !req.linkTarget then return next(404)

        if req.linkDef.multiple
            sendList(req, res, next, req.linkTarget)
        else
            sendModel(req, res, next, req.linkTarget)
    )

    router.patch("/:modelId/:linkName", (req, res, next)->
        child = req.linkTarget
        if !child
            # don't allow creation by PATCH
            return next(404)

        if req.linkDef.multiple
            # don't allow editing an entire collection
            res.set({"Allow": "GET, HEAD, POST"})
            return next(405)

        # don't allow setting id for links
        delete req.body[child.idAttribute]

        child.set(req.body, {editor: req.user})
        saveModel(req, res, next, child)
    )

    router.put("/:modelId/:linkName", (req, res, next)->
        child = req.linkTarget
        if !child
            # don't allow creation by PUT
            return next(404)

        if req.linkDef.multiple
            # don't allow editing an entire collection
            res.set({"Allow": "GET, HEAD, POST"})
            return next(405)

        req.body[child.idAttribute] = child.id
        child.attributes = req.body
        child.set(child.attributes, {editor: req.user})

        saveModel(req, res, next, child)
    )

    router.post("/:modelId/:linkName", (req, res, next)->
        TargetCtor = require("models/"+req.linkDef.target)
        targetProto = TargetCtor.prototype

        # don't allow setting id for links
        delete req.body[targetProto.idAttribute]

        child = new TargetCtor(req.body)
        unless child.isValid({editor: req.user})
            res.status(403)
            return next(new Error(child.validationError))
        child.save({}, {wait: true, editor: req.user}).then(->
            parent = req.model

            if req.linkDef.multiple
                # add to the list of links
                children = parent.getLink(req.params.linkName) or []
                children.push(child)
                isValid = parent.setLink(req.params.linkName, children, {editor: req.user})
            else
                # replace any existing link
                oldChild = req.linkTarget
                # TODO: determine if this has made an orphan of a 'cascadeDelete' link
                isValid = parent.setLink(req.params.linkName, child, {editor: req.user})
            unless isValid
                res.status(403)
                return next(new Error(parent.validationError))
            parent.save({}, {wait: true, editor: req.user}).then(->
                res.status(201)
                res.location(child.url()) # no need to do a full redirect
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

    router.delete("/:modelId/:linkName", (req, res, next)->
        parent = req.model
        oldChild = req.linkTarget
        if !oldChild
            return next(404)

        isValid = parent.removeLink(req.params.linkName, {editor: req.user})
        unless isValid
            res.status(403)
            return next(new Error(parent.validationError))
        parent.save({}, {wait: true, editor: req.user}).then(->
            res.location(parent.url())
            res.status(204)
            res.end()
            # TODO: also destroy the orphaned child?
        , next)
    )

    return router.middleware

# ***
# ***NEXT**: Step into [DUST-RENDERER.COFFEE](dust-renderer.html) and observe how it overrides the current
# `res.render()` function, or step into [ERROR-HANDLER.COFFEE](error-handler.html) and see how it is designed to
# process errors.*
