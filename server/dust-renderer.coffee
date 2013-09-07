fsPath = require("path")
dust = require("../client/dust-helpers")

# dust works best with plain objects
makeContext = (args...)->
    context = dust.makeBase({})
    for arg in args when arg
        obj = {}
        for key, val of arg
            obj[key] = val
        context = context.push(obj)
    return context

# During development, we want to reload templates that have changed on disk.
# Emptying the dust cache will cause them to be reloaded.
# But if templates get cached as a side-effect of a require() extension,
# we must also empty the relevant require() cache.
# This can cause a synchronous file read during a callback,
# so it is not suitable for production.
invalidateCache = (views)->
    dust.cache = {}

    viewsDir = fsPath.resolve(views)
    # regex to match any module in viewsDir or any module that ends in .dust
    recompilable = new RegExp("^"+viewsDir+"|\\.dust$", 'g')
    for key, val of require.cache
        if key.match(recompilable)
            delete require.cache[key]

# the default res.render() does not support streaming
# so we override it with one that does
responsePrototype = require("express/lib/response")
responsePrototype.render = (view, options={}, callback)->
    res = this
    req = res.req
    app = res.app

    if app.get('env') is 'development'
        invalidateCache(app.get('views'))

    if typeof options is 'function'
        callback = options
        options = {}

    # provide a default handler to send template errors inline
    if !callback
        callback = (err)->
            return res.end() unless err
            
            if res.headersSent
                message = 'Error'
                if app.get('env') is 'development'
                    message = err.toString()
                res.end("[Template #{message}]")
            else
                next(err)

    context = makeContext(app.locals, res.locals, options)

    if !req.xhr
        context.global.mainView = view
        view = 'layout'

    stream = dust.stream(view, context)
    stream.on('data', (data)->
        return unless data.length > 0
        
        unless res.headersSent
            # enable streaming to browser
            res.writeContinue()
            res.writeHead(res.statusCode or 200, {'Content-Type': 'text/html'})
        res.write(data)
    )
    stream.on('error', callback)
    stream.on('end', callback)
