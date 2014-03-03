BaseView = require("base/view")

module.exports = class TableRowView extends BaseView
    # A view that provides its requirePath can be re-instantiated after serialization
    requirePath: module.id

    # The CSS class for this view
    className: "table-row-view"

    tagName: "tr"

    # BaseView's `render()` function uses the subclass's provided template
    template: require("./template")

    initialize: (options)->
        @columns = options.columns or @model?.fields or []
        if window?
            @listenTo(@model, 'sync', @render)
