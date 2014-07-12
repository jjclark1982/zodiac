BaseView = require("base/view")

module.exports = class BackgroundJobView extends BaseView
    # A view that provides its requirePath can be re-instantiated after serialization
    requirePath: module.id

    # The CSS class for this view
    className: "background-job-view"

    # BaseView's `render()` function uses the subclass's provided template
    template: require("./template")

    # When this view is presented by a router, the window title will be set to this
    title: ()->
        return @model.get("name")

    hydrate: ->
        @listenTo(@model, "change:status", @updateStatus)
        @pollInterval = setInterval(=>
            console.log("polling:", @model, @model.get("status"))
            @model.fetch()
        , 1000)

    updateStatus: ()->
        @render()
        if @model.get("status") in ["finished", "failed"]
            clearInterval(@pollInterval)
            setTimeout(=>
                @remove()
            , 1000)
