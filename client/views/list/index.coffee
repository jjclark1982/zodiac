BaseView = require("views/base")
animationLength = 10

module.exports = class ListView extends BaseView
    requirePath: module.id.replace(/^.*\/client\/|(\/index)?(\.[^\/]+)?$/g, '')
    template: require("./template")
    className: "list-view"
    tagName: "ul"

    initialize: (options)->
        @itemView ?= @options.itemView or 'activity'
        @itemViewCtor = require("views/"+@itemView)
        @collection ?= new Backbone.Collection()
        @listenTo(@collection, "add", @insertItemView)
        @listenTo(@collection, "remove", @removeItemView)
        @listenTo(@collection, "sort", @populateItems)
        @listenTo(@collection, "reset", @populateItems)
        @listenTo(@collection, "request", @syncStarted)
        @listenTo(@collection, "sync", @syncFinished)
        @listenTo(@collection, "error", @syncError)
        @listenTo(@collection, "filter", @filter)
        @listenToOnce(@collection, "sync", ->
            @collection.trigger("filter")
        )
        # @listenTo(@collection, "all", ->console.log(arguments))
        return @

    syncStarted: (collection, xhr, options = {})->
        @$el.addClass("loading")
        xhr.always(=>
            @syncFinished(collection, xhr, options)
        )

    syncFinished: (collection, xhr, options = {})->
        @$el.removeClass("loading")

    syncError: (collection, xhr, options = {})->
        @$el.addClass("error").attr("data-error", "#{xhr.status} #{xhr.statusText}")

    populateItems: (collection=@collection, options={})->
        # ensure that @modelViews only has current items
        @modelViews ?= {}
        for cid, subview of @subviews or {} when subview.model?
            @modelViews[subview.model.cid] = subview
        for cid, subview of @modelViews
            if subview.model.collection isnt collection
                @removeItemView(model)

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
            }, @options.itemViewOptions)
            itemView = new @itemViewCtor(options)
            itemView.render()
            @subviews[itemView.cid] = itemView
            @modelViews[model.cid] = itemView
        return itemView

    removeItemView: (model)->
        return unless model
        @$lis = null
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

        @$el.children().detach()
        # TODO: figure out why each li was being duplicated on load

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
            countStr = "#{count} " + (if count is 1 then 'activity' else 'activities')
            @$(".num-found").text("Found #{countStr} matching your criteria")
        )
        return @
