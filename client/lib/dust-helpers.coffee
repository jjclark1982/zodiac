if window?
    dust = window.dust
    CommonDustjsHelpers = window.CommonDustjsHelpers
else
    dust = require("dustjs-linkedin")
    try
        CommonDustjsHelpers = require("common-dustjs-helpers").CommonDustjsHelpers
    if process.env.DUST_RETAIN_WHITESPACE
        dust.optimizers.format = (ctx, node)->node

if CommonDustjsHelpers
    commonDustjsHelpers = new CommonDustjsHelpers()
    commonDustjsHelpers.export_helpers_to(dust)

module.exports = dust

# reusable tmpl function that imitates dust.load() based on a relative path.
loadRelativeTmpl = (chunk, context)->
    relativeName = context.templateName # this will have been set by the main partial handler
    parentName = context.get("$parentTemplate")
    absName = resolvePath(parentName, relativeName)
    context.templateName = absName
    dust.onLoad(absName, (err, src)->
        if err then return chunk.setError(err)
        if !dust.cache[absName]
            dust.loadSource(dust.compile(src, absName))
        dust.cache[absName](chunk, context).end()
    )

resolvePath = (from, to)->
    currentPath = from.split(/\//)
    currentPath.pop() # the directory we are starting from

    toParts = to.split(/\//)
    for toPart in toParts
        if toPart is '..'
            currentPath.pop()
        else if toPart is '.'
            null
        else
            currentPath.push(toPart)
    return currentPath.join('/')

getSuperview = (context)->
    cursor = context.stack
    while cursor?.head
        if cursor.head instanceof Backbone.View
            return cursor.head
        cursor = cursor.tail
    return null

getViewOptions = (context)->
    # a context is a list of frames:
    # current context, parameters to this partial, parent context, grandparent context, etc.
    # we usually want to use the parameters to this partial.
    # with no parameters, use the parent context unless it is a view (which would clobber things like className).
    # this allows us to include arbitrary options passed in to res.render() without merging.
    options = context.stack?.tail?.head or context.stack?.head or {}
    if options instanceof Backbone.View
        return {}
    return options

# dust.render('page') triggers require('views/page')
# usage: {>page mainView=mainView options=options /}
# {>"{itemView}" model=. tagName="li" />
dust.onLoad = (name, callback)->
    # if name is a relative path, hand off to the resolver
    if name[0] is '.'
        dust.register(name, loadRelativeTmpl)
        return callback()

    # otherwise, load a module by its absolute path
    try
        # this should find subclasses of BaseView in the normal places
        # and plain .dust files given a full enough path
        BaseView = require("lib/view")
        loadedModule = BaseView.requireView(name)
    catch e
        return callback(e)

    if loadedModule.prototype?.registerSubview
        # this appears to be a backbone view
        ViewCtor = loadedModule
        tmpl = (chunk, context)->
            superview = getSuperview(context)
            options = getViewOptions(context)

            try
                view = new ViewCtor(options)
                superview?.registerSubview?(view)
            catch e
                return chunk.setError(e)

            return chunk.map((branch)->
                tagName = view.tagName or 'div'
                attrString = view.attrString()
                branch.write("\n<#{tagName} #{attrString}>")

                try
                    view.templateContext((err, locals)->
                        if err then return branch.setError(err)

                        # create a context with the parent's globals and this view's locals
                        locals.$parentTemplate = name
                        childContext = dust.makeBase(context.global).push(locals)
                        branch = view.template(branch, childContext)
                        branch.write("</#{tagName}>")
                        if process?.env?.NODE_ENV is 'development'
                            branch.write("<!-- end of \"#{name}\" view -->")
                        branch.write("\n")
                        branch.end()
                    )
                catch e
                    branch.setError(e)
            )

        dust.register(name, tmpl)
        return callback()

    else
        # this appears to be a compiled dust template
        tmpl = (chunk, context)->
            childContext = context.push({$parentTemplate: name})
            loadedModule(chunk, childContext)

        dust.register(name, tmpl)
        return callback()

dust.helpers or= {}

dust.helpers.keyvalue = (chunk, context, bodies, params={})->
    items = params.object or context.current()
    if typeof items is 'function'
        items = items()

    for key, value of items
        ctx = {"key" : key, "value" : value}
        chunk = chunk.render(bodies.block, context.push(ctx))

    return chunk

dust.helpers.contextDump = (chunk, context, bodies, params={})->
    to = params.to or 'output'
    key = params.key or 'current'
    try
        if (key is 'full')
            array = []
            cursor = context.stack
            while cursor
                array.push(cursor.head or context.global)
                cursor = cursor.tail
            dump = JSON.stringify(array, null, '  ')
        else
            dump = JSON.stringify(context.current(), null, '  ')
    catch e
        dump = e
    if (to is 'console')
        console.log(dump)
        return chunk
    else
        return chunk.write(dump)

dust.filters or= {}

# Support for using arbitrary data in a css class
# Usage: <span class="field-named-{fieldName|className}">{value}</span>
#        <style>.field-named-last-modified { display: none; }</style>
dust.filters.className = (value) ->
    return value.replace(/\W+/g, '-')

# When assigning JSON data to a variable in an inline <script>,
# use this filter to prevent injection with </script> in a string.
# Usage: <script>var x = {x|js|inlineScript|s};</script>
dust.filters.inlineScript = (value)->
    return value.replace(/<\//g, "<\\/")

dust.filters.date = (value)->
    return $?.format.date( new Date( value ), 'MMMM yyyy' )

