require("dust-helpers") # define the subview loader helper
if !Backbone?
    global._ = require('underscore')
    global.Backbone = require('backbone')

module.exports = class BaseView extends Backbone.View
    # A class must provide its require path so that it can be attached
    requirePath: module.id.replace(/^.*\/client\/|(\/index)?(\.[^\/]+)?$/g, '')

    className: 'base-view'

    superview: null

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

    templateContext: ->
        return @

    # subclasses should override this function to provide content
    template: (context, callback)->
        callback(new Error("No template provided for #{@className}"))
        return ''

    getInnerHTML: (callback)->
        context = _.result(@, 'templateContext')
        @template(context, callback)

    # server-side function that does not require a DOM
    getOuterHTML: (callback)->
        attrs = _.defaults({}, _.result(@, 'attributes'))
        if (@id)
            attrs.id = _.result(@, 'id')
        if (@className)
            attrs['class'] = _.result(@, 'className')

        attrString = (for key, value of attrs when value?
            ''+key+'="' + value.toString().replace(/"/g, '\\"') + '"'
        ).join(" ")

        @getInnerHTML((err, inner)->
            outer = "<#{@tagName} #{attrString}>#{inner}</#{@tagName}>"
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
            if @collection.model is subviow.model.constructor and !subview.model.collection?
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
