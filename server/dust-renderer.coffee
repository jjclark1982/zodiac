# # dust-renderer.coffee
# ### Rendering re-do

# *This file overrides the default `res.render()` function with an asynchronous version.*
# ***

fs = require("fs")
fsPath = require("path")
# Load [DUST-HELPERS.COFFEE](../client/dust-helpers.html): custom-written helpers for Dust templating 
dust = require("lib/dust-helpers")
BaseView = require("lib/view")

if process.env.NODE_ENV is 'development'
    dust.isDebug = true
    dust.debugLevel = 'WARN'

# Publish a Node.js require() handler for .dust files
if (require.extensions)
    setDustAlias = (filename)->
        if process.env.NODE_PATH
            alias = filename.replace(process.cwd()+'/'+process.env.NODE_PATH+'/', '')
            alias = alias.replace(/^views\//,'')
            alias = alias.replace(/\.dust$/,'')
            dust.cache[alias] = dust.cache[filename]

    loadDustFile = (filename, callback)->
        if callback
            # async version
            fs.readFile(filename, 'utf8', (err, text)->
                if err then return callback(err)
                source = dust.compile(text.trim(), filename)
                tmpl = dust.loadSource(source, filename)
                setDustAlias(filename)
                callback(null, tmpl)
            )
        else
            # sync version
            text = fs.readFileSync(filename, 'utf8')
            source = dust.compile(text.trim(), filename)
            tmpl = dust.loadSource(source, filename)
            setDustAlias(filename)
            return tmpl

    require.extensions[".dust"] = (module, filename)->
        tmpl = loadDustFile(filename)
        module.exports = tmpl
        module.exports.render = (context, callback)->
            dust.render(filename, context, callback)
        module.exports.stream = (context)->
            dust.stream(filename, context)
        module.exports.reload = (callback)->
            loadDustFile(filename, callback)

# Dust works best with plain JS objects. This function merges one ore more items
# of any kind into a flat object, with later values overwriting earlier ones.
merge = (args...)->
    result = {}
    for obj in args
        for key, val of obj
            result[key] = val
    return result

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

# This behaves much like Express's standard render function, but also supports streaming
render = (viewName, options={}, callback)->
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
                req.next(err)

    # unless we get a request to partially render content, render the [`layout`](../../client/views/layout.dust) view,
    # passing it the view associated with the current model as a `mainView` variable.
    if !req.xhr
        try
            options.title ?= BaseView.requireView(viewName).prototype.title
        options.mainView = viewName
        viewName = 'layouts/webpage'

    # make app and res locals available globally
    # so that all subviews can access the site name, the current user, etc
    globals = merge(app.locals, res.locals)
    context = dust.makeBase(globals).push(options)

    stream = dust.stream(viewName, context)
    stream.events = { data: [], error: [], end: [] } # prevent warnings
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

middleware = (req, res, next)->
    res.render = render
    next()

module.exports = middleware

# ***
# ***NEXT**: Step into [RESOURCE.COFFEE](resource.html) to see how the riak database and middleware factory are set up
# or step into [ERROR-HANDLER.COFFEE](error-handler.html) and see how it is designed to process errors.*

#Actually, if we've gotten this far, we probably want to start looking into views...
