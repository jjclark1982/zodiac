unless window?
    global._ = require('lodash')
    global.Backbone = require('backbone')

module.exports = class BaseModel extends Backbone.Model
    requirePath: module.id
    defaultView: 'generic'
    defaultListView: 'table'
    urlRoot: null
    bucket: null

    title: ->
        titleAtt = _.result(@, 'titleAttribute')
        name = @get("name")
        if titleAtt
            return @get(titleAtt)
        else if name
            return name
        else
            return @id

    index: -> {
        all: "1"
    }

    linkedModels: ->
        if @_linkedModels then return @_linkedModels
        @_linkedModels = {}
        for linkName, linkDef of @links or {}
            if linkDef.type isnt "hasOne"
                throw new Error("links of type #{linkDef.type} are not yet supported")

            targetId = @get("_links")?[linkName]
            if !targetId then continue

            TargetCtor = require("models/"+linkDef.target)
            atts = {}
            atts[TargetCtor.prototype.idAttribute] = targetId
            @_linkedModels[linkName] = new TargetCtor(atts)

        return @_linkedModels

    getLink: (linkName)->
        return @linkedModels()[linkName]

    setLink: (linkName, target)->
        linkDef = @links[linkName]
        if !linkDef
            throw new Error("unknown link type: "+linkName)
        links = _.clone(@attributes._links) or {}
        oldTargetId = links[linkName]
        links[linkName] = target.id
        @set("_links", links)
        return oldTargetId

    removeLink: (linkName)->
        links = _.clone(@attributes._links) or {}
        oldTargetId = links[linkName]
        delete links[linkName]
        @set("_links", links)
        return oldTargetId
