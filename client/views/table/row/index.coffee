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
            @listenTo(@model, 'sync', @render) #TODO: respond to all events so this won't be needed
            @listenTo(@model, 'change', @fillInputs)

    events: {
        "keyup input": "typeInput"
        "change input": "changeInput"
        "click .save-item": "saveItem"
        "click .fetch-item": "fetchItem"
        "click .destroy-item": "destroyItem"
    }

    fillInputs: (model, options)->
        for name, val of model.changedAttributes()
            $input = @$("[name='#{name}']")
            $input.val(val) unless $input.val() is val

    readInput: ($input)->
        name = $input.attr("name")
        fieldDef = @model.fieldDefs()[name]
        switch fieldDef.type
            when 'number'
                value = parseFloat($input.val())
            when 'boolean'
                value = $input.is(":checked")
            else
                value = $input.val()
        @model.set(name, value)

        if @model.changedAttributes()
            @$(".save-item").removeAttr("disabled")
            @$(".fetch-item").removeAttr("disabled")
    
    saveItem: (event)->
        $(event.currentTarget).attr("disabled", true)
        # TODO: display any validation error
        @model.save()

    fetchItem: (event)->
        $(event.currentTarget).attr("disabled", true)
        for key in @model.keys() when key isnt @model.idAttribute
            @model.unset(key, {silent: true})
        @model.fetch()

    destroyItem: (event)->
        @model.destroy()

    typeInput: (event)->
        $input = $(event.currentTarget)
        @readInput($input)

    changeInput: (event)->
        $input = $(event.currentTarget)
        @readInput($input)
        if @model.collection?.comparator
            @model.collection.sort()
