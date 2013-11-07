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
        @listenTo(@, 'render:after', ->
            @$(".container").empty().append(view.$el)
        )
        @show()
    
    show: ->
        $(document.body).css({
            "overflow": "hidden"
            "padding-right": getScrollBarWidth() + "px"
        })
        $(document.body).append(@$el)
        @render()

    clickBackground: (event)->
        if event.target.parentElement is @el
            @dismiss()

    pressEscape: (event)=>
        if event.keyCode is 27
            @dismiss()

    dismiss: ->
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
