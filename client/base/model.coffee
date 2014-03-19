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
            linkName = linkDef.name
            targetId = @get(linkName)
            continue unless targetId

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
        @unset(linkName, options)
