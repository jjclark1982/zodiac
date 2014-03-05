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

    # Convert any ids stored in this model's "_links" attribute
    # into the format for storing with riak-js
    linkKeys: ->
        linkIds = @get("_links")
        if !linkIds then return

        linkKeys = []
        for linkName, linkDef of @links or {}
            if linkDef.type isnt "hasOne"
                throw new Error("links of type #{linkDef.type} are not yet supported")

            TargetCtor = require("models/"+linkDef.target)
            targetBucket = TargetCtor.prototype.bucket
            unless targetBucket
                throw new Error("cannot store a link that has no bucket defined")

            childId = linkIds[linkName]
            if childId
                linkKeys.push({
                    tag: linkName
                    bucket: targetBucket
                    key: childId
                })

        return linkKeys
