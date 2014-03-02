require("dust-helpers") # define the subview loader helper
unless window?
    global._ = require('lodash')
    global.Backbone = require('backbone')
    Backbone.View.prototype._ensureElement = (->)
    Backbone.View.prototype.delegateEvents = (->)

Query = require("models/query")

normalizePath = (requirePath='')->
    return requirePath.replace(/^.*\/client\/|(\/index)?(\.[^\/]+)?$/g, '')

module.exports = class BaseView extends Backbone.View
    # A class that provides its requirePath can be re-instantiated after serialization
    requirePath: module.id

    className: 'base-view'

    # A view must keep track of its subviews to facilitate garbage-collection and re-rendering
    subviews: null
    
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

        #the cid is useful on the client, but don't include it over the wire
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
            @model.fetch({
                success: =>
                    @model.needsData = false
                    callback(@)
                error: (model, response, options)=>
                    callback(response?.responseJSON or response or "fetch error")
            })
        else if @collection?.needsData
            @collection.fetch({
                success: =>
                    @collection.needsData = false
                    callback(@)
                error: (collection, response, options)=>
                    callback(response?.responseJSON or response or "fetch error")
            })
        else
            callback(@)

    # subclasses should override this function to provide content
    template: (context, callback)->
        callback(new Error("No template provided for #{@className}"))
        return ''

    getInnerHTML: (callback)->
        @templateContext((context)=>
            try
                @template.render(context, callback)
            catch e
                callback(e)
        )

    # server-side function that does not require a DOM
    getOuterHTML: (callback)->
        tagName = @tagName or 'div'
        @getInnerHTML((err, inner)=>
            outer = "<#{tagName} #{@attrString()}>#{inner}</#{tagName}>"
            callback(err, outer)
        )

    render: ->
        @trigger("render:before")
        @$el.addClass("rendering")
        @getInnerHTML((err, html)=>
            if err
                @$el.addClass("error").attr("data-error", err.message)
                return
            @$el.html(html)
            @$el.removeClass("rendering")

            # the template will have populated @subviews
            @attach()
        )
        return @

    attach: ($element)->
        if $element? and $element isnt @$el
            @setElement($element)

        @$el.attr('data-cid', @cid)
        @$el.addClass(_.result(@, 'className'))
        @$el.data('viewAttached', true)

        @attachSubviews()
        @trigger("render:after")
        return @

    attachSubviews: ->
        @subviews or= {}
        for cid, subview of @subviews
            $el = @$("[data-cid=#{cid}]")
            unless $el.data('viewAttached')
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
