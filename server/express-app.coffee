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

app.use(express.favicon())
app.use(express.static(path.resolve(__dirname, '../build')))

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
