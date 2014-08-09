unless window?
    global._ = require('lodash')
    global.Backbone = require('backbone')

module.exports = class BaseModel extends Backbone.Model
    requirePath: module.id
    defaultView: 'form'
    defaultListView: 'table'
    urlRoot: null
    bucket: null
    idAttribute: 'id'
    titleAttribute: 'name'

    # subclasses may override this to construct a title from their data
    title: ->
        titleAtt = _.result(@, 'titleAttribute')
        return @get(titleAtt) or ''

    slug: ->
        title = _.result(@, 'title')
        # remove html entities and punctuation
        slug = title.replace(/&.*?;|['"]/g, '')
        # join words with dashes, remove dashes from both ends
        slug = slug.replace(/[^\w]+/g, '-').replace(/^-|-$/g,'')
        return slug

    urlWithSlug: ->
        url = _.result(@, 'url')
        slug = _.result(@, 'slug')
        if slug and (slug isnt @id)
            url += '-'+slug
        return url

    # by default, add every model to the "all" index for its bucket
    # subclasses should override this with their specific indexing rules
    index: -> {
        all: "1"
    }

    # each model defines its fields as an array. this method supports looking up a field by name
    fieldDefs: ->
        if @_fieldDefs then return @_fieldDefs

        fieldDefs = {}
        for fieldDef in @fields
            fieldDefs[fieldDef.name] = fieldDef

        # cache the lookup table in the prototype to support other models of the same class
        @__proto__._fieldDefs = fieldDefs
        return fieldDefs

    # instantiate ready-to-fetch models for the links defined in a model's data
    linkedModels: ->
        @_linkedModels ?= {}
        for linkDef in (@fields or []) when linkDef.type is "link"
            @_linkedModels[linkDef.name] ?= @getLink(linkDef.name)

        return @_linkedModels

    getLink: (linkName)->
        linkDef = @fieldDefs()[linkName]
        return undefined unless linkDef

        targetId = @get(linkName)
        if targetId and @_linkedModels?[linkName]
            return @_linkedModels[linkName]

        TargetCtor = require("models/"+linkDef.target)
        if linkDef.multiple
            items = []
            for id in (targetId or [])
                atts = {}
                atts[TargetCtor.prototype.idAttribute] = id
                items.push(atts)
            target = new Backbone.Collection(items, {model: TargetCtor})
            target.url = _.result(@, 'url') + "/" + linkName

        else if targetId
            atts = {}
            atts[TargetCtor.prototype.idAttribute] = targetId
            target = new TargetCtor(atts)

        else return null

        @_linkedModels ?= {}
        @_linkedModels[linkName] = target
        return target

    setLink: (linkName, target, options)->
        linkDef = @fieldDefs()[linkName]
        if linkDef.multiple
            items = target.models or target or []
            @set(linkName, (i.id for i in items), options)
        else
            @set(linkName, target.id, options)

    removeLink: (linkName, options)->
        @set(linkName, null, options)

# Each subclass can call loadFromUrl() to instantiate a model from its url.
# If that model has already been fetched in this window, it will be de-duplicated.
# The caller is responsible for clearing the cache to prevent memory leaks.
# 
# Usage:
#     User = require("models/user")
#     me = User.loadFromUrl("/users/me")
BaseModel.loadFromUrl = (url, options={})->
    Constructor = this

    # when there is no url, instantiate a model of the right type
    if !url
        return new Constructor({}, options)

    # Guess the id if it fits the urlRoot pattern.
    # this isn't very RESTful, but it really helps with de-duplication
    if @prototype.urlRoot
        urlRootRE = new RegExp("^" + @prototype.urlRoot + "/")
        if url.match(urlRootRE)
            id = url.replace(urlRootRE, '')

    # when url is /random, don't use the cache
    # TODO: make this work with cache-control headers instead of special-casing this url
    if id is 'random'
        model = new Constructor({}, options)
        model.url = url
        model.fetch(options) unless options.fetch is false
        return model

    # otherwise, check the cache for a model with this url
    @_modelsByUrl ?= {}
    model = @_modelsByUrl[url]
    unless model
        atts = {}
        if id
            atts[@prototype.idAttribute] = id
        model = new Constructor(atts, options)
        model.url = url
        @_modelsByUrl[url] = model
        model.once('sync', =>
            # update the cache with multiple urls for the same model
            receivedUrl = _.result(model, 'url')
            defaultUrl = @prototype.url.apply(model)
            for alias in [receivedUrl, defaultUrl] when alias isnt url
                existing = @_modelsByUrl[alias]
                if existing and existing isnt model
                    console.warn("Duplicate models for url #{alias}", model, existing)
                @_modelsByUrl[alias] = model
        )
        model.fetch(options) unless options.fetch is false
    return model
