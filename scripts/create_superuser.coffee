db = require ("../server/db")
require ("../server/backbone-sync-riak")
crypto = require("crypto")
User = require("models/user")

hash = require ("../server/passport-config").hash

superuser = new User({username: "admin"})
atts = superuser.attributes

hash("admin", (err, salt, hash)->
    atts.password_hash = hash.toString('base64')
    atts.password_salt = salt
    superuser.save()
)


atts.permissions = ["admin"]
superuser.save()
