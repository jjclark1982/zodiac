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
        return callback(e)

    unless module.prototype?.requirePath
        # this must be a plain dust template
        return callback()

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
