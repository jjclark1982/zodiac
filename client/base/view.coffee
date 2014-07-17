require("dust-helpers") # define the subview loader helper
unless window?
    global._ = require('lodash')
    global.Backbone = require('backbone')
    Backbone.View.prototype._ensureElement = (->)
    Backbone.View.prototype.delegateEvents = (->)

Query = require("models/query")

# The BaseView class provides lifecycle functions for subclasses to inherit
module.exports = class BaseView extends Backbone.View
    # A class that provides its requirePath can be re-instantiated after serialization
    requirePath: module.id

    className: 'base-view'

    # A view must keep track of its subviews to facilitate garbage-collection and re-rendering
    subviews: null
    
    # Provide a title for the window when this view is navigated to.
    # Subclasses may override this if they want specific logic or static strings
    title: ->
        mainObj = @collection or @model or {}
        return _.result(mainObj, 'title') or ''

    # Serialize all the information needed to instantiate this view.
    # Subclasses that need additional options should extend this method.
    attributes: ->
        atts = {}
        atts['data-view'] = normalizePath(@requirePath).replace(/^views\//,'')
        if @model?.requirePath
            atts['data-model'] = normalizePath(@model.requirePath).replace(/^models\//,'')
        if @collection?.requirePath
            atts['data-collection'] = normalizePath(@collection.requirePath)
        if @collection?.model
            cmp = normalizePath(@collection.model.prototype.requirePath).replace(/^models\//,'')
            if cmp then atts['data-collection-model'] = cmp

        try
            atts['data-model-url'] = _.result(@model, 'url')
        try
            curl = _.result(@collection, 'url')
            query = new Query(@collection?.query, {parse: true}).toString()
            if query then curl += "?" + query
            atts['data-collection-url'] = curl

        # the cid is useful as a weak link in the browser, but don't include it over the wire
        if window?
            atts['data-cid'] = @cid

        return atts

    attrString: ->
        attrs = _.defaults({}, _.result(@, 'attributes'))
        if (@id)
            attrs.id = _.result(@, 'id')
        if (@className)
            attrs['class'] = _.result(@, 'className')

        str = (for key, value of attrs when value?
            ''+key+'="' + value.toString().replace(/"/g, '&quot;') + '"'
        ).join(" ")
        return str

    templateContext: (callback)->
        # TODO: make it more clear that this simply returns @ at the correct time
        # rendering asynchronously means we can pass a model into a view before it has data
        if @model?.needsData
            @model.fetch().then(=>
                @model.needsData = false
                callback(null, @)
            , (err)->
                if err.statusCode is 404
                    # show an empty view if the model got this far with no data
                    callback(null, @)
                else
                    callback(err)
            )

        else if @collection?.needsData
            @collection.fetch().then(=>
                @collection.needsData = false
                callback(null, @)
            , callback)

        else
            callback(null, @)

    # subclasses should override this function to provide content
    template: (chunk, context)->
        chunk.setError("No template provided for #{@className}")

    getInnerHTML: (callback)->
        @templateContext((err, context)=>
            try
                @template.render(context, callback)
            catch e
                callback(e)
        )

    # server-side function that does not require a DOM
    # note that this is currently made rendundant by the streaming version in dust-helpers
    getOuterHTML: (callback)->
        tagName = @tagName or 'div'
        @getInnerHTML((err, inner)=>
            outer = "<#{tagName} #{@attrString()}>\n#{inner}\n</#{tagName}>"
            callback(err, outer)
        )

    render: ->
        unless window?
            throw new Error("Tried to render #{@constructor.name} without a DOM")
        @trigger("render:before")
        @preRender?()
        @$el.addClass("rendering")
        @unstickit()
        @getInnerHTML((err, html)=>
            if err
                @$el.addClass("error").attr("data-error", err.message)
                console.error(err)
                return
            @$el.html(html)
            @$el.removeClass("rendering")

            # the template will have populated @subviews
            @attach()
        )
        return @

    # after a view is serialized for transmission or inclusion in a superview,
    # it must be reattached to the correct element
    attach: ($element)->
        if $element? and $element isnt @$el
            @setElement($element)

        @$el.attr('data-cid', @cid)
        @$el.addClass(_.result(@, 'className'))
        @$el.data('viewAttached', true)

        @attachSubviews()
        if @model and @bindings
            @stickit()
        @postRender?()
        @trigger("render:after")
        return @

    attachSubviews: ->
        # when rendering a view with subviews, the subviews are initialized with dummy elements
        # and then rendered to the text of the parent element
        # once that text is parsed into elements,
        # each subview can be attached to the element with the matching data-cid
        @subviews or= {}
        for cid, subview of @subviews
            $el = @$("[data-cid=#{cid}]")
            unless $el.data('viewAttached')
                # render() will not have been called by the dust partial,
                # so call preRender functions here instead
                subview.preRender?()
                subview.trigger("render:before")
                subview.attach($el)

    registerSubview: (subview)->
        @subviews or= {}
        @subviews[subview.cid] = subview

        # if this is a collection view and the subview is for a model in that collection:
        # add the model to the collection
        if @collection and subview.model
            if @collection.model is subview.model.constructor and !subview.model.collection?
                url = _.result(subview.model, 'url')
                if url.indexOf(@collection.url) is 0
                    subview.model.id ?= url.replace(@collection.url + '/', '')
                @collection.add(subview.model)
        return @

    remove: ->
        for cid, subview of @subviews or {}
            subview.remove?()
        @subviews = null
        super(arguments...)

    constructor: ->
        # The default constructor sets @model and @collection and runs @initialize()
        super(arguments...)

        if window?
            @hydrate?()

    # Automatically set some classes and data attributes in response to common events.
    # Subclasses may opt out of this by redefining hydrate() without a call to super()
    hydrate: ->
        @trigger("hydrate")
        if @model
            @listenTo(@model, 'request', (object, xhr, options)->
                if object is @model
                    @$el.addClass('loading')
            )
            @listenTo(@model, 'sync', (object, response, options)->
                if object is @model
                    @$el.removeClass('loading')
            )
            @listenTo(@model, 'error', (object, xhr, options)->
                if object is @model
                    @$el.removeClass('loading')
                    errString = "#{xhr.status} #{xhr.statusText}"
                    try
                        errString += ": " + JSON.parse(xhr.responseText).message
                    @$el.addClass('error').attr("data-error", errString)
                    @$(".show-when-error").attr("title", errString)
            )
            @listenTo(@model, 'invalid', (model, error, options)->
                @$el.removeClass('loading')
                @$el.addClass('invalid').attr("data-validation-error", error)
                # TODO: standardize field-specific validation error structure
            )
            # @listenTo(@model, 'destroy', (model, collection, options)->
            #     @listenToOnce(model, 'sync', (model, response, options)->
            #         @remove()
            #     )
            # )
        
        if @collection
            @listenTo(@collection, 'request', (object, xhr, options)->
                if object is @collection
                    @$el.addClass('loading')
            )
            @listenTo(@collection, 'sync', (object, response, options)->
                if object is @collection
                    @$el.removeClass('loading')
            )
            @listenTo(@collection, 'error', (object, xhr, options)->
                if object is @collection
                    @$el.removeClass('loading')
                    errString = "#{xhr.status} #{xhr.statusText}"
                    try
                        errString += ": " + JSON.parse(xhr.responseText).message
                    @$el.addClass('error').attr("data-error", errString)
            )

# transform a module id into a path that can be required on client or server
normalizePath = (requirePath='')->
    return requirePath.replace(/^.*\/client\/|(\/index)?(\.[^\/]+)?$/g, '')

# load a view given its normalized path. works the same as require(name) for full paths
# Usage:
# ListView = BaseView.requireView("list")
BaseView.requireView = (name)->
    paths = ['views/', 'widgets/', 'pages/', '']
    for path in paths
        try
            View = require(path+name)
        catch e
            lastError = e
    if View
        return View
    else
        throw lastError
