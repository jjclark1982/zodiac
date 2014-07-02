express = require("express")
db = require("./db")

module.exports = class RiakStore extends express.session.Store
    constructor: (options = {})->
        @bucket = options.bucket or 'sessions'
        bucketOptions = {
            backend: "memory_mult",
            precommit: [{name: "Precommit.validateJSON", language: "javascript"}]
        }
        db.saveBucket(@bucket, bucketOptions, (err)=>
            if err
                @emit("disconnect")
                @checkConnection()
        )
        process.nextTick(=>
            @emit("disconnect")
            @checkConnection()
        , 1)
        return this

    checkConnection: =>
        db.ping((err, isAlive)=>
            if isAlive
                @emit("connect")
            else
                @emit("disconnect")
                setTimeout(@checkConnection, 30*1000)
        )

    get: (sid, callback)->
        db.get(@bucket, sid, (err, session, meta)=>
            if err
                if err.statusCode is 404
                    return callback() # no item found - ok to create one
                else
                    @emit("disconnect")
                    @checkConnection()
                    e = new Error("Unable to load session: "+err.message)
                    e.statusCode = 502
                    return callback(e)
            return callback(null, session)
            # TODO: resolve links
        )

    set: (sid, session, callback)->
        options = {}
        # TODO: make a link to the user
        db.save(@bucket, sid, session, options, callback)

    destroy: (sid, callback)->
        db.remove(@bucket, sid, callback)
