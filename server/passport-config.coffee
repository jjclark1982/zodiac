crypto = require("crypto")
url = require("url")
express = require("express")
passport = require("passport")
LocalStrategy = require("passport-local").Strategy
gatewayError = require("./gateway-error")
require("./backbone-sync-riak")
User = require("models/user")

# cryptographic hash function
hash = (password, salt, callback)->
    # TODO: store password as "#{salt}:#{iterations}:#{hash}"
    keylen = 128
    iterations = 12345
    saltLen = 64
    if callback?
        crypto.pbkdf2(password, salt, iterations, keylen, callback)
    else
        # when there is no "salt" argument, create a salt and save it
        callback = salt
        crypto.randomBytes(saltLen, (err, salt)->
            if err then return callback(err)
            salt = salt.toString('base64')
            crypto.pbkdf2(password, salt, iterations, keylen, (err, hash)->
                if err then return callback(err)
                callback(null, salt, hash)
            )
        )

validatePassword = (password='')->
    if password.length < 5
        return "password must be at least 5 characters long"
    return null

passport.serializeUser((user, callback)->
    callback(null, user.id)
)

passport.deserializeUser((id, callback)->
    user = new User()
    user.id = id
    user.fetch().then(->
        callback(null, user)
    , (err)->
        if err.statusCode is 404
            return callback(null, null) # log in as nobody
        else
            return callback(gatewayError(err))
    )
)

passport.use(new LocalStrategy((username, password, done)->
    user = new User()
    user.id = username
    user.fetch().then(->
        hash(password, user.get("password_salt"), (err, hash)->
            if err then return done(err)

            if hash.toString("base64") is user.get("password_hash")
                return done(null, user)
            else
                return done(null, false, {message: "wrong password"})
        )

    , (err)->
        if err.statusCode is 404
            return done(null, false, {message: "no such user"})
        else
            return done(gatewayError(err))
    )
))

middleware = express()

middleware.use(passport.initialize())
middleware.use(passport.session())

# make the user available to views
middleware.use((req, res, next)-> 
    res.locals.session = req.session
    res.locals.currentUser = req.user
    return next()
)

# hash any received passwords before continuing
middleware.use((req, res, next)->
    if req.url.match(/^\/users/) and req.body?.password?
        passwordError = validatePassword(req.body.password)
        if passwordError
            res.status(403)
            return next(new Error(passwordError))

        hash(req.body.password, (err, salt, hash)->
            req.body.password_hash = hash.toString('base64')
            req.body.password_salt = salt
            delete req.body.password
            next()
        )
    else
        next()
)

# disallow editing for non-logged-in users
middleware.use((req, res, next)->
    # allow read-only methods
    if req.method in ["GET", "HEAD", "OPTIONS"]
        return next()

    # allow logging in and creating accounts
    else if req.url in ['/login', '/logout', '/users'] and req.method is "POST"
        return next()

    # allow logged-in users to try other methods
    else if req.session?.passport?.user
        return next()
        
    else
        res.status(401)
        return next(new Error("You must be logged in to do that."))

    # TODO: disallow editing based on csrf token
)

# alias `/users/me` to the logged-in user, if any
middleware.use((req, res, next)->
    if req.url.indexOf('/users/me') is 0
        if req.session?.passport?.user
            req.url = req.url.replace(/^\/users\/me($|\/|\?)/, '/users/'+req.session.passport.user+'$1')
        else
            res.status(401)
            return next(new Error("You are not logged in."))
    next()
    # the resource middleware for User will then process this as /users/id
)

middleware.get('/login', (req, res, next)->
    # a page will handle this, but putting a handler here helps to give the correct OPTIONS response
    next()
)

middleware.post('/login', (req, res, next)->
    callback = (err, user, info, status)->
        if err then return next(err)

        if user
            req.logIn(user, (err)->
                if err then return next(err)

                if req.xhr
                    # when logging in by ajax form, send the location of the logged-in user
                    res.redirect(user.url())
                else
                    # redirect to a page that had a login form shown due to a 401
                    target = url.parse(req.get("referer") or '').pathname # strip host
                    if !target or (target is "/login")
                        target = "/" # default redirect after login
                    res.redirect(target)
            )
        else
            res.status(401)
            res.format({
                json: ->
                    res.json({error: info})
                html: ->
                    res.locals.flash ?= []
                    info = [info] unless info instanceof Array
                    for loginError in info
                        res.locals.flash.push(loginError.message)
                    # option to avoid leaking information about whether an account exists:
                    # res.locals.flash = ["Incorrect login or password"]
                    res.render("login")
                default: ->
                    message = info[0]?.message or info.message
                    res.type("text")
                    res.send(message)
            })

    passport.authenticate('local', callback)(req, res, next)
)

middleware.get('/logout', (req, res, next)->
    # a page will handle this, but putting a handler here helps to give the correct OPTIONS response
    next()
)

middleware.post('/logout', (req, res, next)-> 
    req.logout()
    if req.xhr
        res.status(204)
        res.end()
    else
        target = url.parse(req.get("referer") or '').pathname # strip host
        if !target or (target is "/logout")
            target = "/" # default redirect after logout
        res.redirect(target)
)

module.exports = middleware
module.exports.hash = hash
