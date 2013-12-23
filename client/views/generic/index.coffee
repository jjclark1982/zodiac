BaseView = require("views/base")

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
        @listenTo(@model, "request", @syncStarted)
        @listenTo(@model, "sync", @syncFinished)
        @listenTo(@model, "error", @syncError)
        if @model.fields
            @fields = @model.fields
        else
            @fields = ({name: k, type: "string"} for k in @model.keys)

    syncStarted: (model, xhr, options)->
        @$el.addClass("loading")

    syncFinished: (model, xhr, options)->
        @$el.removeClass("loading")

    syncError: (collection, xhr, options = {})->
        @$el.removeClass("loading")
        @$el.addClass("error").attr("data-error", "#{xhr.status} #{xhr.statusText}")
        try
            message = JSON.parse(xhr.responseText).message

        catch e
            message = ""

        @$(".show-when-error").attr("title", "#{xhr.status} #{xhr.statusText}: #{message}")

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
                @model.save(@model.attributes, {"success": () =>
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
