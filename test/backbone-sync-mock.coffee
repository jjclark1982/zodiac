require("lib/backbone-sync-metadata") # load this first so we get metadata like 'model.url' set after fetch

oldSync = Backbone.sync
Backbone.sync = (method, model, options)->
    switch method
        when "read"
            # use the regular sync method for read-only operations
            oldSync(method, model, options)
        else
            # simulate success for all other operations
            # TODO: support simulating errors
            console.log("running mock sync", arguments)
            response = _.clone(model.attributes)
            status = "success"
            xhr = {}
            options.success?(response, status, xhr)

    # TODO: return a promise, to support syntax like model.save().then(...)
