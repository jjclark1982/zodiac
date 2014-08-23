session = require("express-session")
db = require("./db")
gatewayError = require("./gateway-error")
Promise = require('bluebird')

MEMORY_CACHE_TTL = parseInt(process.env.MEMORY_CACHE_TTL) or 1000 # one second

module.exports = class RiakStore extends session.Store
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

    cache: {}
    cacheTimeouts: {}
    updateTimeout: (sid)->
        if @cacheTimeouts[sid]
            clearTimeout(@cacheTimeouts[sid])
        @cacheTimeouts[sid] = setTimeout(=>
            @cache[sid] = null
        , MEMORY_CACHE_TTL)

    get: (sid, callback)->
        promise = @cache[sid] or new Promise((resolve, reject)=>
            db.get(@bucket, sid, (dbErr, session, meta)=>
                if session isnt Object(session)
                    # data is not in the expected format
                    dbErr ?= new Error(session)
                    @emit("disconnect")
                if dbErr
                    if dbErr.statusCode is 404
                         # no item found - ok to create one
                        return resolve()

                    err = gatewayError(dbErr)
                    if err.statusCode is 504
                        # unable to connect to database
                        @emit("disconnect")
                        @checkConnection()

                    return reject(err)
                        
                return resolve(session)
                # TODO: follow links
            )
        )

        promise.then((session)=>
            @updateTimeout(sid)
            callback(null, session)
        , (err)->
            callback(err)
        )
        @updateTimeout(sid)

    set: (sid, session, callback)->
        @cache[sid] = new Promise((resolve, reject)->
            resolve(session)
        )
        @updateTimeout(sid)

        options = {}
        # TODO: make a link to the user
        db.save(@bucket, sid, session, options, callback)

    destroy: (sid, callback)->
        @cache[sid] = null
        db.remove(@bucket, sid, callback)
