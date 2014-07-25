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

# dust.render('page') triggers require('views/page')
# usage: {>page mainView=mainView options=options /}
# {>"{itemView}" model=. tagName="li" />
dust.onLoad = (name, callback)->
    try
        # this should find subclasses of BaseView in the normal places
        # and plain .dust files given a full enough path
        BaseView = require("base/view")
        loadedModule = BaseView.requireView(name)
    catch e
        return callback(e)

    if loadedModule.prototype?.registerSubview
        # this appears to be a backbone view
        viewCtor = loadedModule
        # fill in the cache so it doesn't try to compile
        dust.cache[name] = (chunk, context)->
            superview = null
            cursor = context.stack
            while cursor.head
                if typeof cursor.head.registerSubview is 'function'
                    superview = cursor.head
                    break
                cursor = cursor.tail

            # try to match the template params
            # if there are none, use the current context
            options = context.stack.tail?.head or context.stack.head
            # but never use an existing view as a context, that would create a loop
            if options is superview
                options = {}

            try
                view = new viewCtor(options)
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
                        childContext = dust.makeBase(context.global).push(locals)
                        branch = view.template(branch, childContext) unless locals.model?.showSkeletonView
                        branch.write("</#{tagName}>")
                        if process?.env?.NODE_ENV is 'development'
                            branch.write("<!-- end of \"#{name}\" view -->")
                        branch.write("\n")
                        branch.end()
                    )
                catch e
                    branch.setError(e)
            )
    else
        # this appears to be a compiled dust template
        # fill in the cache so it doesn't try to recompile
        dust.cache[name] = loadedModule
    callback()

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
dust.filters.className = (value) ->
    return value.replace(/\W+/g, '-')

dust.filters.date = (value)->
    return $?.format.date( new Date( value ), 'MMMM yyyy' )

