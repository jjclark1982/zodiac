require("dust-helpers") # define the subview loader helper
unless window?
    global._ = require('lodash')
    global.Backbone = require('backbone')
    Backbone.View.prototype._ensureElement = (->)
    Backbone.View.prototype.delegateEvents = (->)

module.exports = class BaseView extends Backbone.View
    # A class must provide its require path so that it can be attached
    requirePath: module.id.replace(/^.*\/client\/|(\/index)?(\.[^\/]+)?$/g, '')

    className: 'base-view'

    subviews: null
    
    attributes: ->
        atts = {
            "data-view": @requirePath.replace(/^views\//,'')
            "data-model": @model?.requirePath?.replace(/^models\//,'')
            "data-collection": @collection?.requirePath
            "data-collection-model":
                @collection?.model?.prototype.requirePath?.replace(/^models\//,'')
        }
        if window?
            atts['data-cid'] = @cid
        try
            atts['data-model-url'] = _.result(@model, 'url')
        try
            atts['data-collection-url'] = _.result(@collection, 'url')
            if @collection?.query
                atts['data-collection-query'] = @collection.query.replace(/^\?/,'')
        return atts

    attrString: ->
        attrs = _.defaults({}, _.result(@, 'attributes'))
        if (@id)
            attrs.id = _.result(@, 'id')
        if (@className)
            attrs['class'] = _.result(@, 'className')

        str = (for key, value of attrs when value?
            ''+key+'="' + value.toString().replace(/"/g, '\\"') + '"'
        ).join(" ")
        return str

    templateContext: (callback)->
        # rendering asynchronously means we can pass a model into a view before it has data
        if @model?.needsData
            @model.fetch({
                success: =>
                    @model.needsData = false
                    callback(@)
                error: (model, response, options)=>
                    callback(response.responseJSON or response or "fetch error")
            })
        else
            callback(@)

    # subclasses should override this function to provide content
    # TODO: treat @template as a (chunk, context) fn
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
