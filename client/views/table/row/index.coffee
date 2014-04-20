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
            @listenTo(@model.collection, 'sync', @setClean)
            @listenTo(@model, 'sync', @setClean)
            @listenTo(@model, 'change', @setDirty)

    events: {
        "click .save-item": "saveItem"
        "click .fetch-item": "fetchItem"
        "click .destroy-item": "destroyItem"
    }

    setClean: ->
        @$(".save-item").attr("disabled", true)
        @$(".fetch-item").attr("disabled", true)

    setDirty: ->
        if @model.changedAttributes()
            @$(".save-item").removeAttr("disabled")
            @$(".fetch-item").removeAttr("disabled")
        if @model.collection?.comparator
            @model.collection.sort()
    
    saveItem: (event)->
        $(event.currentTarget).attr("disabled", true)
        # TODO: display any validation error
        @model.save()

    fetchItem: (event)->
        $(event.currentTarget).attr("disabled", true)
        for key in @model.keys() when key isnt @model.idAttribute
            @model.unset(key)
        @model.fetch()

    destroyItem: (event)->
        @model.destroy()
