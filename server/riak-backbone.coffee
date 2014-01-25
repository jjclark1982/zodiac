db = require("./db")

# Load the [`lodash` node module](http://lodash.com/) globally so that the models that get loaded by the function below
# have access to it. Lodash ~= Underscore, with better performance.
global._ = require('lodash')

# Load the [`backbone` node module](http://backbonejs.org/) globally so that the models that get loaded by the function
# below have access to it
global.Backbone = require('backbone')

Backbone.sync = (method, model, options={})->
    unless model.bucket
        throw new Error("cannot #{method} a model that has no bucket defined")
    bucket = model.bucket

    switch method
        when "create", "update"
            unless model.isValid()
                return options.error?(model.validationError)

            options.returnbody ?= true
            options.vclock ?= model.vclock
            if model.index
                options.index ?= _.result(model, 'index')

            db.save(bucket, model.id, model.toJSON(), options, (err, object, meta)->
                if err then return options.error?(model, meta, options, err)

                object.idAttribute = meta.key
                model.attributes = model.parse(object)
                model.vclock = meta.vclock
                options.success?(model, meta, options)
            )
            model.trigger('request', model, {}, options);

        when "delete"
            db.remove(bucket, model.id, options, (err, object, meta)->
                if err then return options.error?(model, meta, options, err)
                options.success?(model, meta, options)
            )

        when "read"
            db.get(bucket, model.id, options, (err, object, meta)->
                if err then return options.error?(model, meta, options, err)

                model.vclock = meta.vclock
                options.success?(model, meta, options)
            )
        else
            throw new Error("cannot #{method} a model")

    return model
