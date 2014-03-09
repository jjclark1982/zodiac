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

    events: {
        "keyup input": "typeInput"
        "change input": "changeInput"
        "click .save-item": "saveItem"
        "click .fetch-item": "fetchItem"
        "click .destroy-item": "destroyItem"
    }

    saveItem: (event)->
        $(event.currentTarget).attr("disabled", true)
        @model.save()
        # TODO: loading indicator

    fetchItem: (event)->
        $(event.currentTarget).attr("disabled", true)
        for key in @model.keys() when key isnt @model.idAttribute
            @model.unset(key, {silent: true})
        @model.fetch().then(=>
            for input in @$("input")
                $(input).val(@model.get(input.name))
        )
        # TODO: loading indicator

    destroyItem: (event)->
        @model.destroy()
        # TODO: loading indicator, re-add if destroy fails?

    typeInput: (event)->
        $input = $(event.currentTarget)
        name = $input.attr("name")
        value = $input.val()
        @model.set($input.attr("name"), $input.val())

        if @model.changedAttributes()
            @$(".save-item").removeAttr("disabled")
            @$(".fetch-item").removeAttr("disabled")

    changeInput: (event)->
        if @model.collection?.comparator
            @model.collection.sort()
