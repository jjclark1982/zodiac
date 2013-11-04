# # LightboxView
# ### [GENERAL DESCRIPTION]

# *This view is a lightbox*
# ***

BaseView = require("views/base")

module.exports = class LightboxView extends BaseView
    requirePath: module.id
    template: require("./template")
    className: "lightbox-view"
        
    initialize: (options)->
        @listenTo(@, 'render:after', ->
            @$(".hero").prepend(options.heroEl)
        )

    events: {
        "click": "close"
    }
    
    close: (event)->
        if event.target.parentElement is @el or event.target.parentElement.parentElement is @el
            window.history.back()
            @remove()
