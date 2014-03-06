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
