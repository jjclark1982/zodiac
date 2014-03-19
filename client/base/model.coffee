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

    fieldDefs: ->
        fieldDefs = {}
        for fieldDef in @fields
            fieldDefs[fieldDef.name] = fieldDef
        return fieldDefs

    linkedModels: ->
        if @_linkedModels then return @_linkedModels
        @_linkedModels = {}
        for linkDef in @fields when linkDef.type is "link"
            if linkDef.multiple
                throw new Error("multiple links are not yet supported")

            linkName = linkDef.name
            targetId = @get(linkName)
            continue unless targetId

            TargetCtor = require("models/"+linkDef.target)
            atts = {}
            atts[TargetCtor.prototype.idAttribute] = targetId
            @_linkedModels[linkName] = new TargetCtor(atts)

        return @_linkedModels

    getLink: (linkName)->
        return @linkedModels()[linkName]

    setLink: (linkName, target)->
        @set(linkName, target.id)

    removeLink: (linkName)->
        @unset(linkName)
