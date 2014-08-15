# # express-app.coffee
# ### The Big Enchilada

# *This file establishes the order of express middleware files.*
# ***

fsPath = require("path")
express = require("express")

# standard middleware
morgan = require("morgan")
responseTime = require("response-time")
compression = require("compression")
bodyParser = require("body-parser")
methodOverride = require("method-override")
cookieParser = require("cookie-parser")
session = require("express-session")

# engine-specific middleware
resource = require("./resource")
errorHandler = require("./error-handler")
passportConfig = require("./passport-config")
RiakStore = require("./riak-store")
dustRenderer = require("./dust-renderer") # as a side-effect, this will register a require() handler for `.dust` files
apiBlueprint = require("./api-blueprint")

# app-specific content
models = require("models")
pages = require("pages")

# initialize the app
app = express()
app.set("views", "../client")
app.locals.appName = require("../package").name

# at the top of the middleware stack are loggers and timers and static files
unless process.env.SILENT
    if process.env.NODE_ENV is "production"
        app.use(morgan("combined"))
    else
        app.use(morgan("dev"))
app.use(responseTime())
app.use(compression())
app.use(express.static(fsPath.resolve(__dirname, "../build"))) # TODO: stop disk access from slowing dynamic responses

# beyond this point we want to be able to render dynamic responses
app.use(dustRenderer)

# then we add parsers for request data
app.use(bodyParser.urlencoded({extended: false}))
app.use(bodyParser.json())
app.use(cookieParser(process.env.EXPRESS_SECRET or "cookie secret"))
app.use(methodOverride("_method"))

# once requests are parsed we can assemble sessions and user identities
app.use(session({
    secret: process.env.EXPRESS_SECRET or "session secret"
    store: new RiakStore({bucket: "sessions"})
    resave: true
    saveUninitialized: false # TODO: prepare session for anonymous user to login or register
}))
app.use(passportConfig)

# mount each PageView at its defined mountPoint
# for example, the 'home' page mounts at '/'
for pageName, PageView of pages then do (pageName, PageView)->
    mountPoint = PageView.prototype?.mountPoint or "/"+pageName
    app.get(mountPoint, (req, res, next)->
        res.render("pages/"+pageName)
    )
    app.options(mountPoint, (req, res, next)->
        res.set("Allow", "GET").end("GET")
    )

# mount a resource handler for each model that has a defined `urlRoot`
# for example, the 'user' model mounts at '/users/:id'
for modelName, model of models when model.prototype.urlRoot
    app.use(model.prototype.urlRoot, resource({model: model}))

app.get("/api-blueprint", apiBlueprint)

# if no routes have been matched, show "not found" with the branded error handler
app.use((req, res, next)->
    next(404)
)

# app.use((err, req, res, next)->
#     if err is 401 or err.statusCode is 401 or res.statusCode is 401
#         # TODO: redirect to login page
# )

app.use(errorHandler)

# export the application so it can be used as an http server listener
module.exports = app

# ***
# ***NEXT**: Step into [DUST-RENDERER.COFFEE](dust-renderer.html) and observe how it is designed to render tempates,
# step into [RESOURCE.COFFEE](resource.html) to see how the riak database and middleware factory are set up, or step
# into [ERROR-HANDLER.COFFEE](error-handler.html) and see how it is designed to process errors.
