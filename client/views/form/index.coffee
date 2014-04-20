BaseView = require("base/view")
require("toggles")

module.exports = class FormView extends BaseView
    requirePath: module.id
    template: require("./template")
    className: "form-view"

    events: {
        "click form": "clickButton"
        "submit form": "handleSubmit"
        "change input": "readInput"
    }

    initialize: (options)->
        if @model.fields
            @fields = @model.fields
        else
            @fields = ({name: k, type: "text"} for k in @model.keys)
        if window?
            @listenTo(@model, "change", @fillInputs)

    clickButton: (event)->
        @lastClicked = event.target

    handleSubmit: (event)->
        $form = $(event.target)
        query = $form.serialize()
        if @lastClicked?.name
            query += "&" + @lastClicked.name + "=" + $(@lastClicked).val()

        event.preventDefault()
        event.stopPropagation()

        switch $(@lastClicked).val()
            when 'POST', 'PUT'
                @model.save(@model.attributes, {success: () =>
                    @$el.addClass("success")
                    setTimeout( =>
                        @$el.removeClass("success")
                    , 1000)
                })
            when 'DELETE'
                @model.destroy()

    readInput: (event)->
        $input = $(event.target)
        name = $input.attr("name")
        fieldDef = @model.fieldDefs()[name]
        switch fieldDef.type
            when 'number'
                value = parseFloat($input.val())
            when 'boolean'
                value = $input.is(":checked")
            when 'object'
                try
                    value = JSON.parse($input.val())
                catch e
                    @model.trigger('invalid', @model, e)
            else
                value = $input.val()
        @model.set(name, value)

    fillInputs: (model, options)->
        for name, val of model.changedAttributes()
            fieldDef = model.fieldDefs()[name]
            $input = @$("[name='#{name}']")
            switch fieldDef.type
                when 'boolean'
                    $input[0]?.checked = !!val
                when 'object'
                    try
                        $input.val(JSON.stringify(val))
                else
                    $input.val(val) unless $input.val() is val
