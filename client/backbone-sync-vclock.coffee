###

We need to transmit metadata such as the vector clock along with model data.
This can be done with the X-Riak-Vclock header.
We add and remove the metadata here.

The case for collections is more complicated, because we need to ensure that
the right vclock gets assigned to each model.
The hidden _vclock attribute works all right for transmitting this,
but we can also use the header as a key:value list.

###

oldSync = Backbone.sync
Backbone.sync = (method, model, options)->
    if model instanceof Backbone.Model
        if model.vclock
            options.headers ?= {}
            options.headers["X-Riak-Vclock"] = model.vclock

        oldSuccess = options.success
        options.success = (response, status, xhr)->
            vclock = xhr?.getResponseHeader("X-Riak-Vclock")
            if vclock
                model.vclock = vclock
            oldSuccess?(response, status, xhr)

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
