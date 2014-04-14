BaseView = require("base/view")
require("toggles")

module.exports = class GenericView extends BaseView
    requirePath: module.id
    template: require("./template")
    className: "generic-view"

    events: {
        "click form": "clickButton"
        "submit form": "handleSubmit"
        "change input": "updateField"
    }

    initialize: (options)->
        if @model.fields
            @fields = @model.fields
        else
            @fields = ({name: k, type: "string"} for k in @model.keys)

    clickButton: (event)->
        @lastClicked = event.target

    handleSubmit: (event)->
        $form = $(event.target)
        query = $form.serialize()
        if @lastClicked?.name
            query += '&' + @lastClicked.name + "=" + $(@lastClicked).val()

        event.preventDefault()
        event.stopPropagation()

        switch $(@lastClicked).val()
            when 'PUT'
                @model.save(@model.attributes, {success: () =>
                    @$el.addClass("success")
                    setTimeout( =>
                        @$el.removeClass("success")
                    , 1000)
                })
            when 'DELETE'
                @model.destroy()

    updateField: (event)->
        $input = $(event.target)
        if $input.is(':checkbox')
            @model.set(event.target.name, $input.is(':checked'))
        else
            @model.set(event.target.name, $input.val())
