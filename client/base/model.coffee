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
        for linkDef in @fields when linkDef.type is "link"
            @_linkedModels[linkDef.name] ?= @getLink(linkDef.name)

        return @_linkedModels

    getLink: (linkName)->
        linkDef = @fieldDefs()[linkName]
        return undefined unless linkDef

        if @_linkedModels?[linkName] then return @_linkedModels[linkName]
        @_linkedModels ?= {}

        targetId = @get(linkName)
        return null unless targetId

        TargetCtor = require("models/"+linkDef.target)
        if _.isArray(targetId)
            items = []
            for id in targetId
                atts = {}
                atts[TargetCtor.prototype.idAttribute] = id
                items.push(atts)
            target = new Backbone.Collection(items, {model: TargetCtor})

        else
            atts = {}
            atts[TargetCtor.prototype.idAttribute] = targetId
            target = new TargetCtor(atts)

        @_linkedModels[linkName] = target
        return target

    setLink: (linkName, target, options)->
        if _.isArray(target)
            @set(linkName, (t.id for t in target), options)
        else
            @set(linkName, target.id, options)

    removeLink: (linkName, options)->
        @set(linkName, null, options)
