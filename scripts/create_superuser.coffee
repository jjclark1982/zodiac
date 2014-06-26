#!/usr/bin/env coffee

# Create a user with "admin" privileges

# Usage:
# To enter username and password at prompt:
# > create_superuser.coffee
#
# To pass in username and/or password directly:
# > create_superuser.coffee [username] [password]
# or:
# > echo [password] | create_superuser.coffee [username]

require("../server/backbone-sync-riak")
User = require("models/user")
hash = require("../server/passport-config").hash
prompt = require("prompt")

createSuperuser = (username, password)->
    hash(password, (err, salt, hash)->
        superuser = new User({
            username: username
            permissions: ["admin"]
            password_salt: salt
            password_hash: hash.toString("base64")
        })
        superuser.save()
    )

schema = {
    properties: {
        username: {
            required: true
        }
        password: {
            pattern: /...../
            message: "Must be at least 5 characters"
            required: true
            hidden: true
        }
    }
}

prompt.override = {
    username: process.argv[2]
    password: process.argv[3]
}

prompt.start()

prompt.get(schema, (err, result)->
    if err
        console.error(err)
        process.exit(1)

    createSuperuser(result.username, result.password)
)
