BaseView = require("base/view")
animationLength = 10

module.exports = class ListView extends BaseView
    requirePath: module.id
    template: require("./template")
    className: "list-view"
    tagName: "ul"

    events: {
        "click .add-item": "addItem"
    }

    initialize: (options)->
        @itemView ?= options.itemView or 'form'
        if options.itemViewOptions
            @itemViewOptions = options.itemViewOptions
            if _.isString(@itemViewOptions)
                @itemViewOptions = JSON.parse(@itemViewOptions)
        # data-ify all string options?
        @itemViewCtor = require("views/"+@itemView)
        @collection ?= new Backbone.Collection()
        if window?
            @listenTo(@collection, "add", @insertItemView)
            @listenTo(@collection, "remove", @removeItemView)
            @listenTo(@collection, "sort", @populateItems)
            @listenTo(@collection, "reset", @populateItems)
            @listenTo(@collection, "request", @syncStarted)
            @listenTo(@collection, "sync", @syncFinished)
            @listenTo(@collection, "error", @syncError)
            @listenTo(@collection, "filter", @filter)
            # @listenToOnce(@collection, "sync", ->
            #     @collection.trigger("filter")
            # )
            # @listenTo(@collection, "all", ->console.log(arguments))
            @handleScroll = _.debounce(@handleScroll, 100).bind(@)
            @listenTo(@, "hydrate", @handleScroll)
            $(document).on("scroll", @handleScroll)
        return @

    addItem: (event) ->
        if event.target.parentElement isnt @el
            return
        @collection.add({})

    attributes: ->
        args = super(arguments...)
        args["data-item-view"] = @itemView
        return args

    syncStarted: (collection, xhr, options = {})->
        @$el.addClass("loading")
        xhr.always(=>
            @syncFinished(collection, xhr, options)
        )

    syncFinished: (collection, xhr, options = {})->
        # remove "no items found" if we now have items
        if collection.length > 0
            $children = @$el.children("li")
            $children.detach()
            @$el.empty().append($children)
        @$el.removeClass("loading")

    syncError: (collection, xhr, options = {})->
        @$el.addClass("error").attr("data-error", "#{xhr.status} #{xhr.statusText}")

    populateItems: (collection=@collection, options={})->
        # ensure that @modelViews only has current items
        @modelViews ?= {}
        for cid, subview of @subviews or {}
            if collection.contains(subview.model)
                @modelViews[subview.model.cid] = subview
            else
                subview.remove()
                delete @subviews[cid]

        # insert each current item at the correct location
        @$lis = null
        for model, index in collection.models
            @insertItemView(model, collection, _.defaults({at: index}, options))
        @$lis = null

        return @

    insertItemView: (model, collection, options={})->
        itemView = @getItemView(model)
        index = options.at

        # check the current state of the dom
        @$lis or= @$el.children()
        if @$lis.length is 0
            @$el.empty() # remove any 'no items found' text

        wasInDom = (itemView.$el.parent().length > 0)

        if @$lis[index] is itemView.el
            # the item is already in the correct location
            return @

        else if index < @$lis.length
            # insert before the item currently in the target location
            @$lis.eq(index).before(itemView.el)

        else
            # insert at the end
            @$el.append(itemView.el)

        if wasInDom
            @$lis = null
            itemView.$el.addClass("moving-up")
            setTimeout((->itemView.$el.removeClass("moving-up")), 1)
            $moveDown = itemView.$el.next()
            do ($moveDown)->
                $moveDown.addClass("moving-down")
                setTimeout((->$moveDown.removeClass("moving-down")), animationLength)
        else
            @$lis.splice(index, 0, itemView.el)
            itemView.$el.addClass("appearing")
            setTimeout((->itemView.$el.removeClass("appearing")), 1)

        return @

    getItemView: (model)->
        @modelViews or= {}
        @subviews or= {}
        if @modelViews[model.cid]
            itemView = @modelViews[model.cid]
        else for cid, subview of @subviews when subview.model?
            if subview.model is model
                itemView = subview
                break
        unless itemView
            options = _.defaults({}, {
                model: model
                tagName: "li"
            }, @itemViewOptions)
            itemView = new @itemViewCtor(options)
            itemView.render()
            @subviews[itemView.cid] = itemView
            @modelViews[model.cid] = itemView
        return itemView

    removeItemView: (model)->
        return unless model
        @$lis = null
        @modelViews ?= {}
        if @modelViews[model.cid]
            itemView = @modelViews[model.cid]
            delete @modelViews[model.cid]
        else for cid, subview of @subviews when subview.model?
            if subview.model is model
                itemView = subview
                delete @subviews[cid]
                break
        itemView.$el.addClass("disappearing")
        setTimeout(->
            itemView.remove()
        , animationLength)

    filter: ->
        return unless @collection.filterCond

        _.defer(=>
            @populateItems()

            count = 0
            for model in @collection.models
                itemView = @getItemView(model)
                if @collection.filterCond(model)
                    # itemView.$el.show()
                    count++
                else
                    itemView.$el.detach()
            countStr = "#{count} " + (if count is 1 then 'item' else 'items')
            # note: this currently doesn't match any element
            @$(".num-found").text("Found #{countStr} matching your criteria")

            # what is onscreen may have changed, so run the scroll handler
            @handleScroll()
        )
        return @

    remove: ->
        if window?
            $(document).off("scroll", @handleScroll)
        super(arguments...)

    handleScroll: (event)=>
        viewportReached = false
        outOfViewCount = 0
        for cid, view of @subviews
            inView = isInView(view.$el, 100)
            if !inView
                if !viewportReached
                    continue # skip the items above the viewport
                else
                    # skip the items below the viewport
                    break if (++outOfViewCount) > 5 # fix for staggered layouts
            else
                outOfViewCount = 0
                viewportReached = true
                if view.model
                    view.model.needsData ?= (view.model.keys().length is 0)
                    if view.model.needsData
                        # TODO: batch fetches in prototype or in Backbone.Sync
                        # console.log("fetching", _.result(view.model, "url"))
                        view.model.needsData = false
                        view.model.fetch().then((->),
                            (err)->
                                view.model.needsData = true
                        )
        return

isInView = ($el, padding=0)->
    top = $el.offset().top
    bottom = top + $el.height()
    $viewport = $el.offsetParent()
    if $viewport[0] is document.documentElement
        # when the viewport is the entire window, use the window height
        viewTop = $(window).scrollTop()
        viewBottom = viewTop + $(window).height()
    else
        # when the viewport is some scrollable div, make sure it is also visible
        if !isInView($viewport, padding)
            return false
        viewTop = $viewport.scrollTop()
        viewBottom = viewTop + $viewport.height()

    if top < (viewBottom+padding) and bottom > (viewTop-padding)
        return true
    else
        return false
