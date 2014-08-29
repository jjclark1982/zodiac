BaseView = require("lib/view")
require("lib/toggles")

Backbone.Stickit?.addHandler({
    selector: "form"
    updateModel: false
    updateView: true
    update: ($el, val, model, options)->
        $el.attr("action", _.result(model, 'url'))
})

Backbone.Stickit?.addHandler({
    selector: "a.link-to-model"
    updateModel: false
    updateView: true
    update: ($el, val, model, options)->
        url = _.result(model, 'url')
        $el.attr("href", model.urlWithSlug?() or url)
        $el.text(url)
})

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
        "form": @model.idAttribute
        ".link-to-model": @model.idAttribute
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
                @model.save()
                # TODO: actually use POST when indicated
            when 'DELETE'
                @model.destroy()
