
# # express-app.coffee
# ### The Big Enchilada

# *This file establishes the order of express middleware files.*
# ***

# load the `path` node module
path = require("path")
<<<<<<< HEAD
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
=======

# load the [`express` node module](http://expressjs.com/)
express = require("express")
# load the [custom dust renderer](dust-renderer.html) (and replace the existing express renderer)
require("./dust-renderer")
# load [server resources](resource.html)
resource = require("./resource")
# load the [custom error handler](error-handler.html)
errorHandler = require("./error-handler")

# Instantiate the listener for the server
app = express()

# All of the views renderable by express live in `/client`
app.set('views', '../client/views')
# Map the local appname variable to the name specified in `package.json`
app.locals.appName = require('../package.json').name

# ###### All app.use calls add middleware to the express stack:

# * Tell the loggger feature of `express` to log requests in production
>>>>>>> 23cd9ed... update internal docs
app.configure('production', ->
    app.use(express.logger())
)
# * Support compressed content-encodings (compress & decompress)
app.use(express.compress())
# * Parse JSON (i.e. **"{'hello': 'world'}"**) content-type
app.use(express.json())
# * Parse urlencoded (i.e. **"message=hello%20world"**) content-type
app.use(express.urlencoded())
# * Parse simulated methods via `PUT` or `DELETE`, (i.e. `<input type="hidden" name="_method" value="put" />`)
# to support progressive enhancement of plain HTML forms
>>>>>>> 10a6237... view fix
app.use(express.methodOverride())
<<<<<<< HEAD
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
=======
# * Parse the `Cookie` header field and populate req.cookies with cookie names, passing in either the `EXPRESS_SECRET`
# variable in the `environment`, or a custom secret variable.
app.use(express.cookieParser(process.env.EXPRESS_SECRET or 'cookie secret'))
# * Provide cookie-based sessions & populate req.session with cookie data
app.use(express.cookieSession())
# * Load favicons
app.use(express.favicon())
# * Load static URLs defined in the /build directory
app.use(express.static(path.resolve(__dirname, '../build')))
# * For all models in a defined `[list]` that have a defined `urlroot` in their prototype, mount that model at that
# `urlroot`. This loop runs on `require` and generates a mount for all `urlroots` in `model`s in the provided list.
# Those mounts act as pointers to **another** express middleware stack that is generated by the
# [resource.coffee](resource.html) file and maps to the endpoints described in the
# [middleware factory](resource.html#middleware-factory) that it exports.
for model in [require("models/book")] when model.prototype.urlRoot
    app.use(model.prototype.urlRoot, resource({model: model}))
app.use('/genBooks', resource({
    model: require('models/book'),
    itemView: 'generic',
    listView: 'list'}))
# * Check to see if any of the specified [`global routes`](#global-routings) below have been triggered
app.use(app.router)
# * assume a 404 error if none of the above click, pass along via `next()` to [`errorHandler`](error-handler.html)
>>>>>>> 23cd9ed... update internal docs
app.use((req, res, next)->
    next(404)
)
app.use(errorHandler)
<<<<<<< HEAD
<<<<<<< HEAD
=======
###Custom routings###
#MAP '/' to the 'landing' view
>>>>>>> 10a6237... view fix
=======
# ###### Global routings
>>>>>>> 23cd9ed... update internal docs

# MAP '/' to the 'landing' view
app.get('/', (req, res, next)->
    res.render('landing')
)
<<<<<<< HEAD
app.get('/slow', (req, res, next)->
    res.render('slow')
)
app.get('/error/:status', (req, res, next)->
    next(parseInt(req.params.status))
)
=======
# MAP '/slow' to the 'slow' view -- for streaming testing
app.get('/slow', (req, res, next)->
    res.render('slow')
)
# MAP '/error/:status' to the [`errorHandler`](error-handler.html) associated with :status for testing
app.get('/error/:status', (req, res, next)->
    next(parseInt(req.params.status))
)
# MAP '/info' to information about the setup for testing
>>>>>>> 23cd9ed... update internal docs
app.get('/info', (req, res, next)->
    info = {
        session: req.session
        headers: req.headers
        server: req.connection.server
    }
    res.render('page', {model:require("util").inspect(info)})
)

# Exports the application
module.exports = app

# ***
# ***NEXT**: Step into [DUST-RENDERER.COFFEE](dust-renderer.html) and observe how it is designed to render tempates, 
# step into [RESOURCE.COFFEE](resource.html) to see how the riak database and middleware factory are set up, or step
# into [ERROR-HANDLER.COFFEE](error-handler.html) and see how it is designed to process errors.
