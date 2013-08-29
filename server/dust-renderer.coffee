fsPath = require("path")
dust = require("../client/dust-helpers")

makeContext = (args...)->
    context = dust.makeBase({})
    for arg in args when arg
        obj = {}
        for key, val of arg
            obj[key] = val
        context = context.push(obj)
    return context

# remove cached dust views and required view code
# in case it has changed on disk during development
invalidateCache = (views)->
    dust.cache = {}
    viewsDir = fsPath.resolve(views)
    recompilable = new RegExp("^"+viewsDir+"|\\.dust$", 'g')
    for key, val of require.cache
        if key.match(recompilable)
            delete require.cache[key]

require("express/lib/response").render = (view, options={}, callback)->
    res = this
    req = res.req
    app = res.app

    if app.get("env") is 'development'
        invalidateCache(app.get("views"))

    if typeof options is 'function'
        callback = options
        options = {}

    if !callback
        callback = (err)->
            return res.end() unless err
            if res.headersSent
                message = 'Error'
                if app.get("env") is 'development'
                    message = err.toString()
                res.end("[Template #{message}]")
            else
                next(err)

    context = makeContext(app.locals, res.locals, options)

    if !req.xhr
        context.global.mainView = view
        view = 'page'

    # enable streaming to browser
    res.writeContinue()
    res.writeHead(200, {"Content-Type": "text/html"})

    stream = dust.stream(view, context)
    stream.on('data', (data)->
        res.write(data) if data.length > 0
    )
    stream.on('error', callback)
    stream.on('end', callback)
