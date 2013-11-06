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
        "click": "close"
    }

    showView: (view)->
        @listenTo(@, 'render:after', ->
            @$(".container").empty().append(view.$el)
        )
        @show()
    
    show: ->
        $(document.body).css("overflow", "hidden")
        $(document.body).append(@$el)
        @render()

    close: (event)->
        if event.target.parentElement is @el
            @dismiss()

    dismiss: ->
        $(document.body).css("overflow", "")
        window.history.back()
        @remove()

# todo: bind escape key to close
