# # LightboxView
# ### [GENERAL DESCRIPTION]

# *This view is a lightbox*
# ***

BaseView = require("lib/view")

module.exports = class LightboxView extends BaseView
    requirePath: module.id
    template: require("./template")
    className: "lightbox-view hidden"
    
    showView: (view)->
        @navigator = view
        @listenToOnce(@, 'render:after', ->
            @$el.children(".lightbox-content").append(view.$el)
        )
        @show()
    
    show: ->
        $(document).on('keyup', @pressEscape)
        if (window.innerWidth > document.documentElement.clientWidth)
            # hide any background scrollbar
            $(document.body).css({
                "overflow": "hidden"
                "padding-right": getScrollBarWidth() + "px"
            })
        $(document.body).append(@$el)
        @render()
        setTimeout(=>
            @$el.removeClass("hidden")
        , 1)

    dismiss: (options={})->
        @silent = options.silent
        $(document).off('keyup', @pressEscape)
        @$el.addClass("hidden")
        @$el.css({"overflow-y": ""})

    events: {
        "click .navigation-item>*": "clickForeground"
        "click .close-link": "clickBackground"
        "click": "clickBackground"
        "transitionend": "transitionDone"
    }

    clickForeground: (event)->
        return true
        $target = $(event.target)
        if $target.is("a") or $target.is("a *")
            event.stopPropagation()

    clickBackground: (event)->
        $target = $(event.target)
        if $target.parents().length < 6
            @dismiss()

    pressEscape: (event)=>
        if event.keyCode is 27
            @dismiss()

    transitionDone: (event)->
        return unless event.target is @el
        if @$el.hasClass("hidden")
            # done dismissing
            $(document.body).css({
                "overflow": ""
                "padding-right": ""
            })
            @remove()
            @trigger("dismissed") unless @silent
        else
            # done appearing
            @$el.css({"overflow-y": "auto"})

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
