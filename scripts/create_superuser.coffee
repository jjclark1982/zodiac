db = require ("../server/db")
require ("../server/backbone-sync-riak")
crypto = require("crypto")
User = require("models/user")

# cryptographic hash function
hash = (password, salt, callback)->
    keylen = 128
    iterations = 12345
    if callback?
        crypto.pbkdf2(password, salt, iterations, keylen, callback)
    else
        callback = salt
        crypto.randomBytes(keylen, (err, salt)->
            if err then return callback(err)
            salt = salt.toString('base64')
            crypto.pbkdf2(password, salt, iterations, keylen, (err, hash)->
                if err then return callback(err)
                callback(null, salt, hash)
            )
        )


superuser = new User({username: "admin"})
atts = superuser.attributes

hash("admin", (err, salt, hash)->
    atts.password_hash = hash.toString('base64')
    atts.password_salt = salt
    superuser.save()
)


atts.permissions = ["admin"]
superuser.save()
