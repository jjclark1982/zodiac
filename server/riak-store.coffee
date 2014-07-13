express = require("express")
db = require("./db")
gatewayError = require("./gateway-error")

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
        db.get(@bucket, sid, (dbErr, session, meta)=>
            if session isnt Object(session)
                # data is not in the expected format
                dbErr ?= new Error(session)
                @emit("disconnect")
            if dbErr
                if dbErr.statusCode is 404
                     # no item found - ok to create one
                    return callback()

                err = gatewayError(dbErr)
                if err.statusCode is 504
                    # unable to connect to database
                    @emit("disconnect")
                    @checkConnection()

                return callback(err)
                    
            return callback(null, session)
            # TODO: resolve links
        )

    set: (sid, session, callback)->
        options = {}
        # TODO: make a link to the user
        db.save(@bucket, sid, session, options, callback)

    destroy: (sid, callback)->
        db.remove(@bucket, sid, callback)
