###

We need to transmit metadata such as the vector clock along with model data.
Most of this is transmitted as HTTP headers. We add and remove it here.

###

# When receiving a model, set these model properties to these HTTP headers.
# Be careful not to overwrite important properties such as cid.
headersToRead = {
    vclock: "X-Riak-Vclock"
    url: "Location"
    lastMod: "Last-Modified"
}

oldSync = Backbone.sync
Backbone.sync = (method, model, options)->
    if model instanceof Backbone.Model
        # Write headers when sending a model
        if model.vclock
            options.headers ?= {}
            options.headers["X-Riak-Vclock"] = model.vclock

        # Read headers when receiving a model
        oldSuccess = options.success
        options.success = (response, status, xhr)->
            for key, headerName of headersToRead
                value = xhr.getResponseHeader(headerName)
                if value
                    model[key] = value # for example: model.vclock = headers["X-Riak-Vclock"]

            oldSuccess?(response, status, xhr)


    # The case for collections is more complicated, because we need to ensure that
    # the right vclock gets assigned to each model.
    # The hidden _vclock attribute works all right for transmitting this,
    # but we can also use the header as a key:value list.
    if model instanceof Backbone.Collection
        collection = model
        oldSuccess = options.success
        options.success = (response, status, xhr)->
            vclocks = null
            try
                vclocks = JSON.parse(xhr.getResponseHeader("X-Riak-Vclocks"))
            unless vclocks
                vclocks = {}
            collection.once("sync", ->
                for id, vclock of vclocks
                    collection.get(id)?.vclock = vclock
            )
            oldSuccess?(response, status, xhr)

    oldSync(method, model, options)
