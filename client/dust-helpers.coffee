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


# fs = require('fs')
# fsPath = require('path')
# dust.onLoad = (name, callback)->
#     name = name.replace(/(\.dust)?$/, '')
#     filename = fsPath.resolve(__dirname, "../client/#{name}.dust")
#     fs.readFile(filename, 'utf8', (err, result)->
#         try
#             callback(err, result)
#         catch e
#             callback(e)
#     )

###
instead of looking directly for the .dust template,
the onLoad handler could instantiate the named backbone view

the top-level server-side one streams, but everything else can be chunked

e.g.
###

# dust.render('page') triggers require('views/page')

dust.onLoad = (name, callback)->
    try
        module = require("views/"+name)
    catch e
        try
            module = require(name)
        catch e2
            return callback(e2)

    if module.prototype?.requirePath
        # this appears to be a backbone view
        viewCtor = module
        # fill in the cache so it doesn't try to compile
        dust.cache[name] = (chunk, context)->
            cursor = context.stack
            while cursor.tail?.head
                cursor = cursor.tail
            options = cursor.head
            superview = context.stack.head

            view = new viewCtor(options)
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

# render: ->
#     @$el.addClass("rendering")
#     @getInnerHtml((err, html)=>
#         @$el.html(html)
#         @$el.removeClass("rendering")
#         @attach()
#     )


# getInnerHtml: (callback)->
#     context = _.result(@, 'templateContext')
#     @template(context, callback)
#     return @

# ###
# {#collection.models}
#     {>itemView model=. parent=???}
# {/collection.models}


# doesn't give us easy access to the root
# but if we did it as a @helper instead of a >partial
# the helper function could inspect the root
# ###

# view: (chunk, context, bodies, params)->
#     superview = params.superview
#     unless superview
#         cursor = context.stack
#         while cursor.tail
#             cursor = cursor.tail
#         superview = cursor

#     viewCtor = require("views/"+params.type)
#     view = new viewCtor(params)

#     return chunk.map((branch)->
#         view.getOuterHtml((err, html)->
#             if err then throw err
#             branch.write(html)
#             branch.end()
#         )
#     )

# ###
# but if i register a view with dust.register(name, tmpl)
# and the tmpl is of the format (chunk, context)->chunk.end()
# it could insert arbitrary view code between the renderer and the template
# ###

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

        view.$el?.on("input [data-bind=\"#{key}\"]", (event)->
            value = $(event.target).val()
            model.set(key, value)
        )
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
