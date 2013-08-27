if window?
    dust = window.dust
else
    dust = require("dustjs-linkedin")
    if process.env.NODE_ENV is 'development'
        dust.optimizers.format = (ctx, node)->node

module.exports = dust

# Publish a Node.js require() handler for .dust files
if (require.extensions)
    if require.extensions['.dust']
        throw new Error("dust require extension no longer needed")
    require.extensions[".dust"] = (module, filename)->
        fs = require("fs")
        text = fs.readFileSync(filename, 'utf8')
        source = dust.compile(text, filename)
        dust.loadSource(source, filename)
        if process.env.NODE_PATH
            alias = filename.replace(process.cwd()+'/'+process.env.NODE_PATH+'/', '')
            alias = alias.replace(/^views\//,'')
            alias = alias.replace(/\.dust$/,'')
            dust.cache[alias] = dust.cache[filename]
        module.exports = (context, callback)->
            dust.render(filename, context, callback)

        module.exports.text = text

# dust.render('page') triggers require('views/page')
# usage: {>page mainView=mainView options=options /}
# {>"{itemView}" model=. tagName="li" />
dust.onLoad = (name, callback)->
    try
        module = require("views/"+name)
    catch e
        try
            module = require(name)
        catch e2
            return callback(e)

    if module.prototype?.requirePath
        # this appears to be a backbone view
        viewCtor = module
        # fill in the cache so it doesn't try to compile
        dust.cache[name] = (chunk, context)->
            cursor = context.stack
            while cursor.tail?.head
                cursor = cursor.tail
            options = cursor.head
            if options and 'options' of options
                options = options.options
            superview = context.stack.head

            view = new viewCtor(context.stack.tail.head)
            superview?.registerSubview?(view)
            return chunk.map((branch)->
                view.getOuterHTML((err, html)->
                    if !window? then view.stopListening()
                    if err then throw err
                    branch.write(html)
                    branch.end()
                )
            )
    
    callback()

dust.helpers or= {}

# usage: {@bind key='name' tagName='span'}initial value{/bind}
dust.helpers.bind = (chunk, context, bodies, params)->
    view = context.stack.head
    model = view.model
    key = params.key
    tagName = params.tagName or 'span'

    if tagName.match(/^input$/i)
        chunk.write("<#{tagName} data-bind=\"#{key}\" value=\"")
        if bodies.block
            bodies.block(chunk, context)
        else
            chunk.write(model.get(key))
        chunk.write("\" />")

        if window?
            setVal = (event)->
                value = $(event.target).val()
                model.set(key, value)
            view.$el?.on("input [data-bind=\"#{key}\"]", _.throttle(setVal, 30))
            view.listenTo(model, "change:#{key}", (model, value, options)->
                view.$("#{tagName}[data-bind='#{key}']").each((i, el)->
                    # only match elements of this view, not subviews
                    if $(el).parents('[data-cid]').eq(0).data('cid') is view.cid
                        $(el).val(value)
                )
            )
    else
        chunk.write("<#{tagName} data-bind=\"#{key}\">")
        if bodies.block
            bodies.block(chunk, context)
        else
            chunk.write(model.get(key))
        chunk.write("</#{tagName}>")

        view.listenTo(model, "change:#{key}", (model, value, options)->
            view.$("[data-bind='#{key}']").text(value)
        )

    return chunk

dust.helpers.keyvalue = (chunk, context, bodies)->
    items = context.current()

    for key, val of items
        ctx = {"key" : key, "value" : val}
        chunk = chunk.render(bodies.block, context.push(ctx))

    return chunk
