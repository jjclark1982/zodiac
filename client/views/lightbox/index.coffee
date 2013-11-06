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
        $(document.body).css("overflow", "hidden")
        $(document.body).append(@$el)
        @render()

    clickBackground: (event)->
        if event.target.parentElement is @el
            @dismiss()

    pressEscape: (event)=>
        if event.keyCode is 27
            @dismiss()

    dismiss: ->
        $(document.body).css("overflow", "")
        $(document).off('keyup', @pressEscape)
        if (@$el.parent().length > 0)
            window.history.back()
            @remove()
