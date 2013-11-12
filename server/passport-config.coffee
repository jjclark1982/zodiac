crypto = require("crypto")
express = require("express")
passport = require("passport")
LocalStrategy = require("passport-local").Strategy
db = require("./db")

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

validatePassword = (password='')->
    if password.length < 5
        return "password must be at least 5 characters long"
    return null

passport.serializeUser((user, callback)->
    callback(null, user.username)
)

passport.deserializeUser((id, callback)->
    db.get('users', id, (err, user, meta)->
        if err then return next(err)
        callback(null, user)
    )
)

passport.use(new LocalStrategy((username, password, done)->
    db.get('users', username, (err, user, meta)->
        if meta.statusCode is 404
            return done(null, false, {message: "no such user"})
        if err then return done(err)

        hash(password, user.password_salt, (err, hash)->
            if err then return done(err)

            if hash.toString("base64") is user.password_hash
                return done(null, user)
            else
                return done(null, false, {message: "wrong password"})
        )
    )
))

middleware = express()

middleware.use(passport.initialize())
middleware.use(passport.session())
middleware.use((req, res, next)-> 
    res.locals.session = req.session
    res.locals.user = req.user
    return next()
    return next() unless req.session?.passport?.user
    db.get('users', req.session.passport.user, (err, user, meta)->
        if err then return next(err)
        req.login(user, (err)->
            if err then return next(err)
            next()
        )
    )
)
middleware.use(middleware.router)


# remap `/users/me` to the logged-in user, if any
middleware.use((req, res, next)->
    if !req.url.indexOf('/users/me') # starts with
        if req.session.passport.user
            req.url = req.url.replace(/^\/users\/me/, '/users/'+req.session.passport.user)
        else
            return next(401)
    next()
)

# disallow editing for non logged in users
middleware.use((req, res, next)->
    if req.method in ["GET", "HEAD", "OPTIONS"] or req.session?.passport?.user
        return next()
    else
        return next(401)
)

middleware.post('/login', passport.authenticate('local',  {
    successRedirect: '/',
    failureRedirect: '/login',
    failureFlash: false
    # TODO: support showing useful messages
}))

middleware.get('/login', (req, res, next)-> 
    res.render('login')
)

middleware.get('/logout', (req, res, next)-> 
    req.logout()
    res.redirect(req.get("referer") or '/')
)

middleware.post('/users', (req, res, next)->
    db.get('users', req.body.username, (err, user, meta)->
        if meta.statusCode isnt 404
            e = new Error("username #{req.body.username} is already taken")
            e.statusCode = 409
            return next(e)

        passwordError = validatePassword(req.body.password)
        if passwordError
            e = new Error(passwordError)
            e.statusCode = 409
            return next(e)

        hash(req.body.password, (err, salt, hash)->
            req.body.password_hash = hash.toString('base64')
            req.body.password_salt = salt
            delete req.body.password
            next() # let the normal resource handler finish the POST
            # TODO: automatically call req.login()
        )
    )
)

# TODO: disallow editing based on user session, csrf token, etc

module.exports = middleware
