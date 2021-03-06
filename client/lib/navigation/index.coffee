BaseView = require("lib/view")

module.exports = class NavigationView extends BaseView
    # A view that provides its requirePath can be re-instantiated after serialization
    requirePath: module.id

    # The CSS class for this view
    className: "navigation-view"

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
        $newEl = $('<div class="navigation-item">')
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
        oldIndex = @currentIndex
        @currentIndex = index

        view = @items[index]
        if !view
            throw new Error("no view for index #{index}")

        @$el.children().removeClass("current")
        $child = @elForItem(view)
        $child.addClass("current")
        if @currentIndex < oldIndex
            @$el.prepend($child)
        else
            @$el.append($child)

        # remove old ones immediately if we cannot depend on the transitionEnd event
        # TODO: detect this in the "transitionStart" event instead of using modernizr
        unless $("html").is(".csstransitions")
            @$el.chidlren().not(".current").detach()

        # TODO: detect parent scroller more intelligently
        if window.router?.lightbox?
            window.router.lightbox.el.scrollTop = 0
        else
            document.body.scrollTop = 0
        return @currentIndex

    goBack: ->
        newIndex = Math.max(0, @currentIndex-1)
        @goToIndex(newIndex)

    goForward: ->
        newIndex = Math.min(@currentIndex+1, @items.length-1)
        @goToIndex(newIndex)

    events: {
        "transitionend": "transitionEnd"
    }

    transitionEnd: (event)->
        $target = $(event.target)
        return unless $target.is(".navigation-item")
        @$el.children().not(".current").detach()
        return
        # TODO: fine-tune vertical alignment inside lightbox
        if $target.hasClass("current")
            # make sure it is visible
            $target.css({"position": "relative"})
        else
            # make sure it is hidden
            $target.css({"position": "absolute"})

# normally this view should have one child. during a transition it should have two.
# (skipping intermediate pages is fine)
# the child should be a navigation item, so the mainView can focus on its own layout
