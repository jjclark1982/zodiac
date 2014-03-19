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

    setDustAlias = (filename)->
        if process.env.NODE_PATH
            alias = filename.replace(process.cwd()+'/'+process.env.NODE_PATH+'/', '')
            alias = alias.replace(/^views\//,'')
            alias = alias.replace(/\.dust$/,'')
            dust.cache[alias] = dust.cache[filename]

    loadDustFile = (filename, callback)->
        fs = require('fs')
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
            dust.stream(filename, context, callback)
        module.exports.reload = (callback)->
            loadDustFile(filename, callback)


mergeContext = (context)->
    obj = {}
    cursor = context.stack
    while cursor.head
        for key, val of cursor.head
            obj[key] ?= val
        cursor = cursor.tail
    return obj


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

    if module.prototype?.registerSubview
        # this appears to be a backbone view
        viewCtor = module
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
                return chunk.map((branch)->
                    tagName = view.tagName or 'div'
                    attrString = view.attrString()
                    branch.write("<#{tagName} #{attrString}>\n")

                    view.templateContext((err, context)->
                        if err then return chunk.setError(err)

                        # TODO: use the parent's globals instead of {}
                        context = dust.makeBase({}).push(context)
                        branch = view.template(branch, context)
                        branch.write("\n</#{tagName}>\n")
                        branch.end()
                    )
                )
            catch e
                return chunk.setError(e)
    callback()

dust.helpers or= {}

dust.helpers.keyvalue = (chunk, context, bodies)->
    items = context.current()
    if typeof items is 'function'
        items = items()

    for key, val of items
        ctx = {"key" : key, "value" : val}
        chunk = chunk.render(bodies.block, context.push(ctx))

    return chunk

dust.helpers.fieldFor = (chunk, context, bodies, params={})->
    switch params.model
        when "parent" then model = context.stack.tail.head
        else model = params.model

    switch params.type
        when "string"
            input = """<input type="text" name="#{params.name}" class="input-#{params.name}" \
                        value="#{model.get(params.name) or ''}">"""
        when "password"
            input = """<input type="password" name="#{params.name}" class="input-#{params.name}" \
                        value="#{model.get(params.name) or ''}">"""
        when "id"
            if model.get(params.name)?
                url = _.result(model, 'url')
                input = """<a href="#{url}">#{model.get(params.name)}</a>"""
            else
                input = """<input type="text" name="#{params.name}" class="input-#{params.name}" \
                        value="#{model.get(params.name) or ''}">"""
        when "readonly"
            if model.get(params.name)?
                input = model.get(params.name)
            else
                input = """<input type="text" name="#{params.name}" class="input-#{params.name}" \
                        value="#{model.get(params.name) or ''}">"""
        when "boolean"
            input = """<input type="checkbox" name="#{params.name}" class="input-#{params.name}" \
                        value="1" #{if model.get(params.name) then 'checked' else ''}>"""
        when "link"
            target = model.getLink(params.name)
            url = _.result(target, 'url')
            if url
                input = """<a href="#{url}">#{params.name}</a>"""
            else
                input = "<!--no target for #{params.name} link -->"
        else
            input = "<!--no editor supported for this type: #{params.type} -->"

    unless params.showlabel is "0"
        str = """<label class="field-#{params.name}">#{params.name}: """ + input + """</label>"""
    else
        str = input
    return chunk.write(str)

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

dust.filters.attr = (value)->
    return value.replace(/"/g, '&quot;')

dust.filters.date = (value)->
    return $?.format.date( new Date( value ), 'MMMM yyyy' )

