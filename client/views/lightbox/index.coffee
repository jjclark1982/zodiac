# # LightboxView
# ### [GENERAL DESCRIPTION]

# *This view is a lightbox*
# ***

BaseView = require("views/base")

module.exports = class LightboxView extends BaseView
    requirePath: module.id
    template: require("./template")
    className: "lightbox-view"
    
    events: {
        "click": "clickBackground"
    }

    initialize: (options)->
        $(document).on('keyup', @pressEscape)

    showView: (view)->
        @prevTitle = document.title
        document.title = _.result(view, 'title')
        @listenToOnce(@, 'render:after', ->
            @addItem(view)
        )
        @show()
    
    show: ->
        $(document.body).css({
            "overflow": "hidden"
            "padding-right": getScrollBarWidth() + "px"
        })
        $(document.body).append(@$el)
        @render()

    addItem: (view)->
        @items ?= []
        @items.push(view)

        $item = $('<div class="history-item">')
        $item.append(view.$el)

        $items = @$el.children(".history-items")
        $items.append($item)
        if @items.length > 1
            # let a redraw happen after adding so we get the right animation
            setTimeout(=>
                @goToItem(@items.length-1)
            , 1)
        else
            # no horizontal animation
            @goToItem(@items.length-1)

    goToItem: (index)->
        $items = @$el.children(".history-items")
        $items.children().removeClass("present")
        $items.children().eq(index).addClass("present")
        @$el.children(".close-link").attr("href", "javascript:history.go(-#{index+1})")
        return this

    clickBackground: (event)->
        if event.target.parentElement is @el
            @dismiss()

    pressEscape: (event)=>
        if event.keyCode is 27
            @dismiss()

    dismiss: ->
        document.title = @prevTitle
        $(document.body).css({
            "overflow": ""
            "padding-right": ""
        })
        $(document).off('keyup', @pressEscape)
        if (@$el.parent().length > 0)
            window.history.back()
            @remove()


getScrollBarWidth = ()->
    inner = document.createElement('p')
    inner.style.width = "100%"
    inner.style.height = "200px"

    outer = document.createElement('div')
    outer.style.position = "absolute"
    outer.style.top = "0px"
    outer.style.left = "0px"
    outer.style.visibility = "hidden"
    outer.style.width = "200px"
    outer.style.height = "150px"
    outer.style.overflow = "hidden"
    outer.appendChild(inner)

    document.body.appendChild(outer)
    w1 = inner.offsetWidth
    outer.style.overflow = 'scroll'
    w2 = inner.offsetWidth
    if (w1 == w2)
        w2 = outer.clientWidth
    document.body.removeChild(outer)
    return (w1 - w2)


###

<div class="container">
    <div class="history">a</div>
    <div class="present">b</div>
    <div class="future">c</div>
</div>


don't remove future views until animationEnd or cache-invalidation

we don't care about overlapping offscreen, so we can just look at
.container {
    overflow-y: scroll;
}
.container > * {
    left: -100%;
    transition: left 333ms ease;
    position: absolute; // don't contribute to scrollbar
}
.container > .present {
    left: 0;
    position: relative; // support transition
}
.container > .present ~ * {
    left: 100%;
    position: absolute; // don't contribute to scrollbar
}

then we should be able to add a new one by saying
$container.append($newView)
$newView.addClass("present")
$oldView.removeClass("present")


*but*

all this doesn't give us a sense of distance in transition animations
instead what we could do is lay out all the history items horizontally in their container
.history-item {
    float: left;
    width: 100%;
    min-height: 100%;
    overflow-x: auto;
}
.history-items {
    width: 100%;
    overflow: hidden;
    transition: margin-left 333ms ease-in-out;
}

and adjust the margin-left of .history-items to show the correct view;
eg to show view idx i:
@$el.children(".history-items").css({"margin-left": i*-100 + "%"})
then there is no need to apply a 'present' class

but we would be more dependent on keeping offscreen items in memory
and have no great way to stop them from contributing to the scrollbar

###
