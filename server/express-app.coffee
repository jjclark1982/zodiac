path = require("path")
express = require("express")
require("./dust-renderer")
resource = require("./resource")
errorHandler = require("./error-handler")

app = express()

app.set('views', '../client/views')
app.locals.appName = require('../package.json').name

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
for model in [require('models/activity')] when model.prototype.urlRoot
    app.use(model.prototype.urlRoot, resource(model))
app.use(app.router)

# app.use((req, res, next)->
#     if req.method is "OPTIONS"
#         unless res.get("Access-Control-Allow-Methods")
#             res.header("Access-Control-Allow-Methods", "OPTIONS, HEAD, GET")
#         res.send(204)
#     else
#         next()
# )
app.use((req, res, next)->
    next(404)
)
app.use(errorHandler)

app.get('/', (req, res, next)->
    res.render('landing')
)

module.exports = app

