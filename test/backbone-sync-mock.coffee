require("lib/backbone-sync-metadata") # load this first so we get metadata like 'model.url' set after fetch

SIMULATED_LATENCY = 10

oldSync = Backbone.sync
Backbone.sync = (method, model, options={})->
    switch method
        when "read"
            if model._exampleData
                # for example models, respond with their original example data
                return simulatedSuccess(model._exampleData, options)

            else
                # for other models, use the regular sync method for read-only operations
                return oldSync(method, model, options)
        else
            # simulate success for all other operations
            # TODO: support simulating errors
            return simulatedSuccess(model.attributes, options)

simulatedSuccess = (response, options)->
    status = "success"
    xhr = {}

    dfd = new $.Deferred()
    setTimeout(->
        dfd.resolve(_.clone(response), status, xhr)
    , SIMULATED_LATENCY)
    dfd.then(options.success, options.error)

    return dfd.promise()
