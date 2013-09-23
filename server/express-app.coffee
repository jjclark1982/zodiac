path = require("path")
express = require("express")
<<<<<<< HEAD
=======
#load the [custom dust renderer](dust-renderer.html) (and replace the existing express renderer)
>>>>>>> 10a6237... view fix
require("./dust-renderer")
resource = require("./resource")
errorHandler = require("./error-handler")

<<<<<<< HEAD
app = express()

=======
#Instantiate the listener for the server
app = express()

#All of the views renderable by express live in `/client`
>>>>>>> 10a6237... view fix
app.set('views', '../client/views')
app.locals.appName = require('../package.json').name

<<<<<<< HEAD
app.configure('production', ->
    app.use(express.logger())
)
app.use(express.compress())
app.use(express.json())
app.use(express.urlencoded())
=======
####All app.use calls add middleware to the express stack####
#Tell the loggger feature of `express` to log requests in production
app.configure('production', ->
    app.use(express.logger())
)
# Support compressed content-encodings (compress & decompress)
app.use(express.compress())
# Parse JSON (i.e. **"{'hello': 'world'}"**) content-type
app.use(express.json())
# Parse urlencoded (i.e. **"message=hello%20world"**) content-type
app.use(express.urlencoded())

#Parse simulated methods via `PUT` or `DELETE`, (i.e. `<input type="hidden" name="_method" value="put" />`)
# to support progressive enhancement of plain HTML forms
>>>>>>> 10a6237... view fix
app.use(express.methodOverride())
app.use(express.cookieParser(process.env.EXPRESS_SECRET or 'cookie secret'))
app.use(express.cookieSession())
# TODO
# app.use(express.csrf({value: (req)->
#     req.query?._csrf or req.headers['x-csrf-token'] or req.signedCookies.csrfToken
# }))
# app.use((req, res, next)->
#     req.csrfToken((err, token)->
#         if err then return next(err)
#         res.cookie('csrfToken', token, {httpOnly: true, signed: true})
#         res.locals._csrf = token
#         next()
#     )
# )

app.use(express.favicon())
app.use(express.static(path.resolve(__dirname, '../build')))
<<<<<<< HEAD
for model in [require('models/activity')] when model.prototype.urlRoot
    app.use(model.prototype.urlRoot, resource(model))
=======
#For all models in a defined `[list]` that have a defined `urlroot` in their prototype,
#mount that model at that `urlroot`
for model in [require("models/book")] when model.prototype.urlRoot
    app.use(model.prototype.urlRoot, resource(model))
#check to see if any of the specified [`global routes`](#routes) below have been triggered
>>>>>>> 10a6237... view fix
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
<<<<<<< HEAD
=======
###Custom routings###
#MAP '/' to the 'landing' view
>>>>>>> 10a6237... view fix

app.get('/', (req, res, next)->
    res.render('landing')
)
app.get('/slow', (req, res, next)->
    res.render('slow')
)
app.get('/error/:status', (req, res, next)->
    next(parseInt(req.params.status))
)
app.get('/info', (req, res, next)->
    info = {
        session: req.session
        headers: req.headers
        server: req.connection.server
    }
    res.render('page', {model:require("util").inspect(info)})
)

module.exports = app
