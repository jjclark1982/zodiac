###

We need to transmit metadata such as the vector clock along with model data.
This can be done with the x-riak-vclock header.
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
            options.attrs ?= model.toJSON(options)
            options.attrs._vclock = model.vclock
            options.headers ?= {}
            options.headers["x-riak-vclock"] = model.vclock

        oldSuccess = options.success
        options.success = (response, status, xhr)->
            vclock = xhr?.getResponseHeader("x-riak-vclock") or response._vclock
            if vclock
                model.vclock = vclock
                delete response._vclock
            oldSuccess?(response, status, xhr)

    if model instanceof Backbone.Collection
        collection = model
        oldSuccess = options.success
        options.success = (response, status, xhr)->
            vclocks = null
            try
                vclocks = JSON.parse(xhr.getResponseHeader("x-riak-vclocks"))
            unless vclocks
                vclocks = {}
                idAttr = collection.model.prototype.idAttribute
                for item in response or []
                    id = item[idAttr]
                    vclock = item._vclock
                    if vclock
                        vclocks[id] = vclock
                        delete item._vclock
            collection.once("sync", ->
                for id, vclock of vclocks
                    collection.get(id)?.vclock = vclock
            )
            oldSuccess?(response, status, xhr)

    oldSync(method, model, options)
