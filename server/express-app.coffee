path = require("path")
express = require("express")
require("./dust-renderer")
errorHandler = require("./error-handler")
async = require("async")

app = express()

app.set('appName', require('../package.json').name)
app.set('views', '../client/views')
app.configure('production', ->
    app.use(express.logger())
)
app.use(express.compress())
app.use(express.bodyParser())
app.use(express.methodOverride())
app.use(express.cookieParser(process.env.EXPRESS_SECRET or 'cookie secret'))
app.use(express.cookieSession())
app.use(express.csrf({value: (req)->
    req.query?._csrf or req.headers['x-csrf-token'] or req.signedCookies.csrfToken
}))
app.use((req, res, next)->
    res.cookie('csrfToken', req.session._csrf, {httpOnly: true, signed: true})
    res.locals._csrf = req.session._csrf
    next()
)

app.use(express.favicon())
app.use(express.static(path.resolve(__dirname, '../build')))
app.use(app.router)

app.use((req, res, next)->
    if req.method is "OPTIONS"
        unless res.get("Access-Control-Allow-Methods")
            res.header("Access-Control-Allow-Methods", "OPTIONS, HEAD, GET")
        res.send(204)
    else
        next()
)
app.use((req, res, next)->
    next(404)
)
app.use(errorHandler)

module.exports = app


Backbone = require("backbone")
app.get('/', (req, res, next)->
    db.query('activities', {city: "Paris"}, (err, keys, meta)->
        if err then return next(err)
        c = new Backbone.Collection()

        async.map(keys, (key, callback)->
            db.get('activities', key, {}, (err, object, meta)->
                callback(err, object)
            )
        , (err, results)->
            if err then return next(err)
            c = new Backbone.Collection(results)
            c.url = "/activities_by_city/Paris"

            res.render('activities', {
                collection: c
            })
        )

    )
    # res.render('activities', {title: "Homepage - #{app.get('appName')}"})
)

riak = require("riak-js")
servers = process.env.RIAK_SERVERS.split(/,/)

db = riak.getClient({pool:{
    servers: servers
    options: {}
}})

app.get('/activities/:id', (req, res, next)->
    db.get('activities', req.params.id, {}, (err, object, meta)->
        if err then return next(err)
        res.json(object)
    )
)

app.get('/activities_by_city/:city', (req, res, next)->
    db.query('activities', {city: req.params.city}, (err, keys, meta)->
        if err then return next(err)
        async.map(keys, (key, callback)->
            db.get('activities', key, {}, (err, object, meta)->
                callback(err, object)
            )
        , (err, results)->
            if err then return next(err)
            res.json(results)
        )
    )
)
