db = require("./db")
global._ = require('lodash')
global.Backbone = require('backbone')

Backbone.sync = (method, model={}, options={})->
    unless model.bucket
        throw new Error("cannot #{method} a model that has no bucket defined")

    bucket = model.bucket
    idAttribute = model.idAttribute or 'id'

    successHandlers = [options.success]
    success = (object)->
        promise.state = "fulfilled"
        promise.value = object
        for handler in successHandlers
            handler?(object)

    errorHandlers = [options.error]
    error = (err)->
        promise.state = "rejected"
        promise.reason = err
        for handler in errorHandlers
            handler?(err)

    promise = {
        state: "pending"
        value: null
        reason: null
        then: (onFulfilled, onRejected)->
            if promise.state is "fulfilled"
                onFulfilled?(promise.value)
            else if promise.state is "rejected"
                onRejected?(promise.reason)
            else
                successHandlers.push(onFulfilled)
                errorHandlers.push(onRejected)
    }

    callback = (err, object={}, meta={})->
        if err then return error(err)

        object[idAttribute] = meta.key
        model.vclock = meta.vclock
        model.lastMod = meta.lastMod
        model.etag = meta.etag
        options.meta = meta
        success(object)

    switch method
        when "create", "update"
            unless model.isValid()
                return error(model.validationError)

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

    return promise

module.exports = Backbone.sync
