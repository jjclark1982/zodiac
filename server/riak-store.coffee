session = require("express-session")
db = require("./db")
gatewayError = require("./gateway-error")
Promise = require('bluebird')

module.exports = class RiakStore extends session.Store
    constructor: (options = {})->
        @bucket = options.bucket or 'sessions'
        @cacheTTL = options.cacheTTL
        @cacheTTL ?= parseInt(process.env.MEMORY_CACHE_TTL) or 1000 # one second
        @startDisconnected = options.startDisconnected
        @startDisconnected ?= !!process.env.RIAK_START_DISCONNECTED

        bucketOptions = {
            backend: "memory_mult",
            precommit: [{name: "Precommit.validateJSON", language: "javascript"}]
        }
        db.saveBucket(@bucket, bucketOptions, (err)=>
            if err
                @emit("disconnect")
                @checkConnection()
        )

        if @startDisconnected
            # serve null sessions (fast) until establishing a db connection
            process.nextTick(=>
                @emit("disconnect")
                @checkConnection()
            )
        else
            # wait for the first db connection to serve the first session (may timeout)
            @checkConnection()
        
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
            delete @cache[sid]
            delete @cacheTimeouts[sid]
        , @cacheTTL)

    get: (sid, callback)->
        @cache[sid] ?= new Promise((resolve, reject)=>
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

        promise = @cache[sid]

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
