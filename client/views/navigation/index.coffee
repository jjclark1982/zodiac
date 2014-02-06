BaseView = require("views/base")

module.exports = class NavigationView extends BaseView
    # A view that provides its requirePath can be re-instantiated after serialization
    requirePath: module.id

    # The CSS class for this view
    className: "navigation-view"
    tagName: "ul"

    # BaseView's `render()` function uses the subclass's provided template
    template: require("./template")

    initialize: (options)->
        @items = []
        if @$el?.parents().length > 0
            for item in @$el.children()
                view = new Backbone.View({el: item})
                @items.push(view)
        @currentIndex = @items.length-1
        return this

    elForItem: (view)->
        $newEl = $('<li class="navigation-item">')
        $newEl.append(view.$el)
        return $newEl

    # add a new item at the given index, by default at the end
    # if adding to the middle, discard items after the added item
    addItem: (view, index=@items.length)->
        if index > @items.length
            throw new Error("Tried to add navigation item at invalid index")

        # remove no-longer reachable future views from @items and from the dom
        @items.splice(index, @items.length, view)
        @$el.children().slice(@items.length-1).remove()

        # create the navigation item for the view and add it to the dom
        @$el.append(@elForItem(view))

        setTimeout(=>
            @goToIndex(index)
        , 1)
        return this

    prependItem: (view)->
        @items.unshift(view)
        @$el.prepend(@elForItem(view))
        setTimeout(=>
            @goToIndex(0)
        , 1)
        return this

    goToIndex: (index)->
        @currentIndex = index
        @$el.children().removeClass("current").eq(index).addClass("current")
        # TODO: detect parent scroller more intelligently
        if window.router?.lightbox?
            window.router.lightbox.el.scrollTop = 0
        else
            document.body.scrollTop = 0

    goBack: ->
        newIndex = Math.max(0, @currentIndex-1)
        @goToIndex(newIndex)

    goForward: ->
        newIndex = Math.min(@currentIndex+1, @items.length-1)
        @goToIndex(newIndex)

    events: {
        "transitionend .navigation-item": "transitionEnd"
    }

    transitionEnd: (event)->
        return
        $target = $(event.currentTarget)
        if $target.hasClass("current")
            # make sure it is visible
            $target.css({"position": "relative"})
        else
            # make sure it is hidden
            $target.css({"position": "absolute"})


# TODO: detach non-current items from the dom after their transitions finish
# (so they don't impact performance)
# and re-add them before the next transition
