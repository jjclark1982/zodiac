BaseView = require("lib/view")

module.exports = class HomeView extends BaseView
    # A view that provides its requirePath can be re-instantiated after serialization
    requirePath: module.id

    # The CSS class for this view
    className: "home-view"

    title: "New Zodiac App"

    mountPoint: '/'

    # BaseView's `render()` function uses the subclass's provided template
    template: require("./template")

    initialize: (options)->
        @urlRoots = []
        for pageName, Page of require("pages") when pageName isnt 'home'
            @urlRoots.push(Page.prototype.mountPoint or '/'+pageName)
        for modelName, Model of require("models")
            if Model.prototype.urlRoot
                @urlRoots.push(Model.prototype.urlRoot)
