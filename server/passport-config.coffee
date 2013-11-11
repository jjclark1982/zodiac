express = require("express")
passport = require("passport")
LocalStrategy = require("passport-local").Strategy

# cryptographic hash function
crypto = require("crypto")
hash = (password, salt, callback)->
    keylen = 128
    iterations = 12345
    if callback?
        crypto.pbkdf2(password, salt, keylen, iterations, callback)
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



db = require("./db")

passport.serializeUser (user, done) ->
    done(null, user.attributes.username)

passport.deserializeUser (id, done) ->
    done(null, {attributes: {username: id}})


passport.use(new LocalStrategy ((username, password, done) ->
    db.get('users', username, (err, meta, user)->
        if meta.statusCode is 404
            return done(null, false, {message: "no such user"})
        if err then return done(err)

        hash(password, user.password_salt, (err, hash)->
            if err then return done(err)

            if hash is user.password_hash
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
    next()
)

# remap `/users/me` to the logged-in user, if any
middleware.use((req, res, next)->
    if !req.url.indexOf('/users/me') # starts with
        if req.session.passport.user
            req.url = '/users/' + req.session.passport.user.id
        else
            return next(401)
    next()
)

middleware.post('/login', passport.authenticate('local',  {
    successRedirect: '/',
    failureRedirect: '/login',
    failureFlash: true
}))

middleware.get('/login', (req, res, next)-> 
    res.render('login')
)

middleware.get('/logout', (req, res, next)-> 
    req.logout()
    res.redirect('/')
)

module.exports = middleware
