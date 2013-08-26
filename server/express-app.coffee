path = require("path")
express = require("express")
opaqueError = require("connect-opaque-error")

app = express()

app.set('appName', require('../package.json').name)
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
app.use(opaqueError)

module.exports = app


# consolidate = require('consolidate')
# app.set('view engine', 'dust')
# app.set('views', __dirname + '/../client')
# app.engine('dust', consolidate.dust)

dust = require("../client/dust-helpers")
app.get('/', (req, res, next)->
    res.set("Content-Type", "text/html")
    if process.env.NODE_ENV is 'development'
        dust.cache = {}
        for key, val of require.cache
            if key.match(/\.dust$/)
                delete require.cache[key]
    stream = dust.stream('page', {content: "<h1>hello everybody</h1>", list: ['a','b','c']})
    stream.on('error', (err)->
        if res.headersSent
            message = 'Error'
            if process.env.NODE_ENV is 'development'
                message = err.toString()
            res.end("[Template #{message}]")
        else
            next(err)
    )
    stream.on('data', (data)->
        return unless data.length > 0
        res.write(data)
    )
    stream.on('end', ->
        res.end()
    )
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
    db.query('activities', {city: req.params.city}, (err, object, meta)->
        if err then return next(err)
        res.json(object)
    )
)
