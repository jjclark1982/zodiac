BaseView = require("base/view")

module.exports = class HomeView extends BaseView
    # A view that provides its requirePath can be re-instantiated after serialization
    requirePath: module.id

    # The CSS class for this view
    className: "home-view"

    # BaseView's `render()` function uses the subclass's provided template
    template: require("./template")

    initialize: (options)->
        @models = []
        for modelName, Model of require("models")
            if Model.prototype.urlRoot
                @models.push(Model)
