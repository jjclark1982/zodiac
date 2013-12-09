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
                throw err
        )
        return this

    get: (sid, callback)->
        db.get(@bucket, sid, (err, session, meta)->
            if err then return callback(err)
            # TODO: resolve linked objects
            return callback(err, session)
        )

    set: (sid, session, callback)->
        options = {}
        # TODO: make a link to the user
        db.save(@bucket, sid, session, options, callback)

    destroy: (sid, callback)->
        db.remove(@bucket, sid, callback)
