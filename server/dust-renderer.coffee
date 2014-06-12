# # dust-renderer.coffee
# ### Rendering re-do

# *This file overrides the default `res.render()` function with an asynchronous version.*
# ***


fsPath = require("path")
# Load [DUST-HELPERS.COFFEE](../client/dust-helpers.html): custom-written helpers for Dust templating 
dust = require("../client/dust-helpers")

# Dust works best with plain objects. This function takes in a series of arguments and returns a flattened dust 
# `context` that contains a straightforward key: value store of these arguments.
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
# But if templates get cached as a side-effect of a `require()` extension,
# we must also empty the relevant `require()` cache.
# This can cause a synchronous file read during a callback,
# so it is not suitable for production.
invalidateCache = (views)->
    dust.cache = {}

    viewsDir = fsPath.resolve(__dirname, views)
    # regex to match any module in `viewsDir` or any module that ends in `.dust`
    recompilable = new RegExp("^"+viewsDir+"|\\.dust$", 'g')
    for key, val of require.cache
        if key.match(recompilable)
            delete require.cache[key]

# the default `res.render()` does not support streaming
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
                message = err.toString()
                if app.get('env') is 'development'
                    message = err.stack
                res.end("<pre>[Template #{message}]</pre>")
            else
                next(err)

    # unless we get a request to partially render content, render the [`layout`](../../client/views/layout.dust) view,
    # passing it the view associated with the current model as a `mainView` variable.
    if !req.xhr
        try
            options.title ?= require("views/"+view).prototype.title
        options.mainView = view
        view = 'layout'

    context = makeContext(app.locals, res.locals, options, {})
    # TODO: eliminate the vestigal {} at the end of context

    stream = dust.stream(view, context)
    stream.on('data', (data)->
        return unless data.length > 0
        unless res.connection?.writable
            #TODO: place some backpressure on the template
            return
        
        unless res.headersSent
            # enable streaming to browser
            res.writeContinue()
            res.writeHead(res.statusCode or 200, {'Content-Type': 'text/html'})
        res.write(data)
    )
    stream.on('error', callback)
    stream.on('end', callback)
# ***
# ***NEXT**: Step into [RESOURCE.COFFEE](resource.html) to see how the riak database and middleware factory are set up
# or step into [ERROR-HANDLER.COFFEE](error-handler.html) and see how it is designed to process errors.*

#Actually, if we've gotten this far, we probably want to start looking into views...
