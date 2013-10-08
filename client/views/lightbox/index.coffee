# # LightboxView
# ### [GENERAL DESCRIPTION]

# *This view is a lightbox*
# ***

BaseView = require("views/base")

module.exports = class LightboxView extends BaseView
    requirePath: module.id.replace(/^.*\/client\/|(\/index)?(\.[^\/]+)?$/g, '')
    template: require("./template")
    className: "lightbox-view"
        
    initialize: (options)->
        @listenTo(@, 'render:after', ->
            @$(".hero").prepend(@options.heroEl)
        )

    events: {
        "click": "close"
    }
    
    close: (event)->
        if event.target is this.el
            window.history.back()
        