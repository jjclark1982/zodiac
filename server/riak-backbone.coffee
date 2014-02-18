db = require("./db")
global._ = require('lodash')
global.Backbone = require('backbone')

Backbone.sync = (method, model={}, options={})->
    unless model.bucket
        throw new Error("cannot #{method} a model that has no bucket defined")

    bucket = model.bucket
    idAttribute = model.idAttribute or 'id'

    callback = (err, object={}, meta={})->
        if err then return options.error?(err)

        object[idAttribute] = meta.key
        model.vclock = meta.vclock
        options.success?(object)

    switch method
        when "create", "update"
            unless model.isValid()
                return options.error?(model.validationError)

            options.returnbody ?= true
            options.vclock ?= model.vclock
            if model.index
                options.index ?= _.result(model, 'index')

            db.save(bucket, model.id, model.toJSON(), options, callback)

        when "delete"
            db.remove(bucket, model.id, options, callback)

        when "read"
            db.get(bucket, model.id, options, callback)
        else
            throw new Error("cannot #{method} a model")

    model.trigger('request', model, {}, options);
    return model

module.exports = Backbone
