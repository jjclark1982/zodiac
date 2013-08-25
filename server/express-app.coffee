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
page = require("../client/views/page")
app.get('/', (req, res, next)->
    # res.render('page', {content: "hello everybody"})
    # if process.env.NODE_ENV is 'development'
    #     dust.cache = {}
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
    # page({content: "hello everybody"}, (err, result)->
    #     if err then return next(err)
    #     res.send(200, result)
    # )
)


RiakClient = require("riak")
servers = process.env.RIAK_SERVERS.split(/,/)
client_id = 'express-app'
pool_name = 'express-pool'

client = new RiakClient(servers, client_id, pool_name)

app.get('/activities/:id', (req, res, next)->
    client.get('activities', req.params.id, {}, (err, response, object)->
        if err then return next(err)
        res.json(object)
    )
)

app.get('/activities_by_city/:city', (req, res, next)->
    bucket = encodeURIComponent('activities')
    city = encodeURIComponent(req.params.city)

    pool_options = {
        path: "/buckets/#{bucket}/index/city_bin/#{city}"
    }
    client.pool.get(pool_options, (err, response, object)->
        if err then return next(err)
        res.json(JSON.parse(object))
    )
)

    #     $.getJSON("/buckets/activities/index/city_bin/#{city}", (result, status, xhr)->

    # pool_options = {
    #     path: "/riak/" + encodeURIComponent(bucket) + "/" + encodeURIComponent(this.key) + qs,
    #     headers: this.client.headers(this.options.http_headers),
    #     retry_not_found: this.should_retry
    # };

    # if (this.debug_mode) {
    #     this.client.log("riak request", "pool options: " + JSON.stringify(pool_options));
    # }

    # if (this.options.body) {
    #     this.client.pool[this.method](pool_options, this.options.body, on_response);
    # } else {
    #     this.client.pool[this.method](pool_options, on_response);
    # }
