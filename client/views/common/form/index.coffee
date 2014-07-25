BaseView = require("lib/view")
require("lib/toggles")

module.exports = class FormView extends BaseView
    requirePath: module.id
    template: require("./template")
    className: "form-view"

    events: {
        "click form": "clickButton"
        "submit form": "handleSubmit"
    }

    initialize: (options)->
        if @model.fields
            @fields = @model.fields
        else
            @fields = ({name: k, type: "text"} for k in @model.keys)

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
                # TODO: actually use POST when indicated
            when 'DELETE'
                @model.destroy()
