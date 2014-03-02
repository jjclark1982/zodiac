BaseView = require("base/view")

module.exports = class TableView extends BaseView
    # A view that provides its requirePath can be re-instantiated after serialization
    requirePath: module.id

    # The CSS class for this view
    className: "table-view"

    tagName: "table"

    # BaseView's `render()` function uses the subclass's provided template
    template: require("./template")

    initialize: (options)->
        @columns = options.columns or @collection?.model?.prototype.fields
        if _.isString(@columns)
            @columns = JSON.parse(@columns)
        @listenTo(@collection, "add", @render)
        @listenTo(@collection, "remove", @render)
        @listenTo(@collection, "sort", @render)
        @listenTo(@collection, "reset", @render)
        @listenTo(@collection, "request", @syncStarted)
        @listenTo(@collection, "sync", @syncFinished)
        @listenTo(@collection, "error", @syncError)

    attributes: ->
        atts = super(arguments...)
        atts["data-columns"] = JSON.stringify(@columns)
        return atts

    syncStarted: (collection, xhr, options = {})->
        @$el.addClass("loading")
        xhr.always(=>
            @syncFinished(collection, xhr, options)
        )

    syncFinished: (collection, xhr, options = {})->
        @$el.removeClass("loading")
        @render()

    syncError: (collection, xhr, options = {})->
        @$el.addClass("error").attr("data-error", "#{xhr.status} #{xhr.statusText}")

