BaseView = require("lib/view")
require("lib/toggles")

module.exports = class FormView extends BaseView
    requirePath: module.id
    template: require("./template")
    className: "form-view"

    initialize: (options)->
        if @model.fields
            @fields = @model.fields
        else
            @fields = ({name: k, type: "text"} for k in @model.keys)

    bindings: -> {
        "form": {
            observe: @model.idAttribute
            update: ($el, val, model, options)->
                $el.attr("action", _.result(@model, 'url'))
        }
        ".form-link": {
            observe: @model.idAttribute
            update: ($el, val, model, options)->
                $el.attr("href", @model.urlWithSlug())
                $el.text(_.result(@model, 'url'))
        }
    }

    events: {
        "click form": "clickButton"
        "submit form": "handleSubmit"
    }

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
