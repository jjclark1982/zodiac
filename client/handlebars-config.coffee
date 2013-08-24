module.exports = Handlebars

Handlebars.registerHelper('result', (memo, args..., options)->
    _.reduce(args, _.result, memo)
)
Handlebars.registerHelper('get', (model, key)->
    return model.get(key)
)
Handlebars.registerHelper('inspect', (item, args..., options)->
    result = _.reduce(args, _.result, item)
    return JSON.stringify(result)
)
Handlebars.registerHelper('titleize', (text)->
    if _.isFunction(text.fn)
        text = text.fn(this)
    words = text.split(/[\s_-]+/)
    for word, index in words
        if word and ((word.length > 2) or (index is 0) or (index is words.length-1))
            words[index] = word[0].toUpperCase() + word.substr(1)
    return words.join(" ")
)
Handlebars.registerHelper('camelize', (text)->
    if _.isFunction(text.fn)
        text = text.fn(this)
    return text.replace(/[-_]([a-z])|^([a-z])/g, (match, char)->
        char.toUpperCase()
    )
)

Handlebars.registerHelper('view', (viewName, args..., options = {})->
    parentView = options.hash.parentView or this
    delete options.hash.parentView
    options.hash.parentView = parentView.cid
    options.preloaded = parentViewCid?.options?.preloaded

    if viewName instanceof Backbone.View
        view = viewName
    else
        viewOptions = _.defaults({}, options.hash, args[0])
        viewOptions._csrf = parentView.options?._csrf or parentView._csrf or
            document?.head.querySelector("meta[http-equiv='X-CSRF-Token']")?.content
        viewPath = "views/" + viewName
        ViewConstructor = require(viewPath) # will throw exception if invalid
        view = new ViewConstructor(viewOptions)

    parentView.registerSubview?(view)

    html = view.getOuterHTML()

    unless window?
        view.stopListening()

    return new Handlebars.SafeString(html)
)
