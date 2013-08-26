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

require("express/lib/response").render = (view, options, callback)->
    res = this
    req = res.req
    app = res.app

    # invalidate cached views in case they have changed on disk
    if app.get("env") is 'development'
        dust.cache = {}
        viewsDir = fsPath.resolve(app.get("views"))
        recompilable = new RegExp("^"+viewsDir+"|\\.dust$", 'g')
        for key, val of require.cache
            if key.match(recompilable)
                delete require.cache[key]

    if typeof options is 'function'
        callback = options
        options = null

    if !callback
        callback = (err, result)->
            if err
                if res.headersSent
                    message = 'Error'
                    if app.get("env") is 'development'
                        message = err.toString()
                    res.end("[Template #{message}]")
                else
                    next(err)
            else
                res.end()

    context = makeContext(app.locals, res.locals, options)

    if !req.xhr
        context = context.push({mainView: view})
        view = 'page'

    res.set("Content-Type", "text/html")
    stream = dust.stream(view, context)
    stream.on('data', (data)->
        res.write(data) if data.length > 0
    )
    stream.on('error', callback)
    stream.on('end', callback)
