require("handlebars-config") # define the {{view}} helper

module.exports = class BaseView extends Backbone.View
    # A class must provide its require path so that it can be attached
    requirePath: module.id.replace(/^.*\/app\/|(\/index)?(\.[^\/]+)?$/g, '')

    className: 'base-view'

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
    template: (context)->
        return ""

    getInnerHTML: ->
        context = _.result(@, 'templateContext')
        return @template(context)

    getOuterHTML: ->
        attrs = _.defaults({}, _.result(@, 'attributes'))
        if (@id)
            attrs.id = _.result(@, 'id')
        if (@className)
            attrs['class'] = _.result(@, 'className')

        attrString = (for key, value of attrs when value?
            ''+key+'="' + value.toString().replace(/"/g, '\\"') + '"'
        ).join(" ")

        return "<#{@tagName} #{attrString}>#{@getInnerHTML()}</#{@tagName}>"

    # subclasses may override this function to perform setup that requires a DOM
    preRender: ->
        return @

    render: ->
        @preRender?()
        # @rivets?.unbind()
        @$el.html(@getInnerHTML())
        @attach()
        return @

    # subclasses may override this function to perform binding that requires a DOM
    postRender: ->
        return @

    attach: ($element)->
        if $element? and $element isnt @$el
            @setElement($element)
        window.cachedViews ?= {}
        window.cachedViews[@cid] = @
        @$el.attr('data-cid', @cid)
        @$el.data('view-attached', true)

        parentCid = @$el.parents('[data-view]').eq(0).data('cid')
        parentView = window.cachedViews[parentCid]
        parentView?.registerSubview(@)

        @attachSubviews()
        # @rivets = rivets.bind?(@$el, @)
        @postRender?()
        return @

    attachSubviews: ->
        @subviews ?= {}
        for cid, subview of @subviews
            $el = @$("[data-cid=#{cid}]")
            unless $el.data('view-attached')
                subview.attach($el)

    registerSubview: (subview)->
        @subviews ?= {}
        @subviews[subview.cid] = subview

        # if this is a collection view and we are registering a model view:
        # add the model to the collection
        if @collection and subview.model
            if @collection.model is subviow.model.constructor and !subview.model.collection?
                url = _.result(subview.model, 'url')
                if url.indexOf(@collection.url) is 0
                    subview.model.id ?= url.replace(@collection.url + '/', '')
                @collection.add(subview.model)
        return @

    remove: ->
        delete window.cachedViews[@cid]
        # @rivets?.unbind()
        @subviews = null
        for cid, subview of @subviews or {}
            subview.remove?()
        super(arguments...)

# TODO: remove dependence on window.cachedViews, both here and in router
