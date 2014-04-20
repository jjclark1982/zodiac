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
        fieldDefs = {}
        for fieldDef in @fields
            fieldDefs[fieldDef.name] = fieldDef
        return fieldDefs

    # instantiate ready-to-fetch models for the links defined in a model's data
    linkedModels: ->
        if @_linkedModels then return @_linkedModels
        @_linkedModels = {}
        for linkDef in @fields when linkDef.type is "link"
            linkName = linkDef.name
            targetId = @get(linkName)
            continue unless targetId # deleted links are stored as null

            TargetCtor = require("models/"+linkDef.target)

            if _.isArray(targetId)
                items = []
                for id in targetId
                    atts = {}
                    atts[TargetCtor.prototype.idAttribute] = id
                    items.push(atts)
                @_linkedModels[linkName] = new Backbone.Collection(items, {model: TargetCtor})

            else
                atts = {}
                atts[TargetCtor.prototype.idAttribute] = targetId
                @_linkedModels[linkName] = new TargetCtor(atts)

        return @_linkedModels

    getLink: (linkName)->
        return @linkedModels()[linkName]

    setLink: (linkName, target, options)->
        if _.isArray(target)
            @set(linkName, (t.id for t in target), options)
        else
            @set(linkName, target.id, options)

    removeLink: (linkName, options)->
        @set(linkName, null, options)
