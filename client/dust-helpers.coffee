if window?
    dust = window.dust
else
    dust = require("dustjs-linkedin")

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
        module.exports = {
            purge: ->
                delete dust.cache[filename]
            render: (context, callback)->
                dust.render(filename, context, callback)
            stream: (context)->
                return dust.stream(filename, context)
        }


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

dust.onLoad = (name, callback)->
    if name.match(/\.dust$/)
        try
            require(name)
            return callback()
        catch e
            return callback(e)

    try
        viewCtor = require("views/"+name)
    catch e
        return callback(e)

    # fill in the cache so it doesn't try to compile
    dust.cache[name] = (chunk, context)->
        cursor = context.stack
        while cursor.tail
            cursor = cursor.tail
        superview = cursor.head
        # todo: check if we have actually found the closest instanceof Backbone.View

        view = new viewCtor(context.stack.head)
        superview.registerSubview?(view)
        return chunk.map((branch)->
            view.getOuterHtml((err, html)->
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
