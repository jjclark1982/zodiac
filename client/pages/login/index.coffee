BaseView = require("lib/view")
User = require("models/user")

module.exports = class LoginView extends BaseView
    # A view that provides its requirePath can be re-instantiated after serialization
    requirePath: module.id

    # The CSS class for this view
    className: "login-view"

    # BaseView's `render()` function uses the subclass's provided template
    template: require("./template")

    title: "Login"

    events: {
        "click form": "clickButton"
        "submit form": "handleSubmit"
    }

    clickButton: (event)->
        @lastClicked = event.target

    handleSubmit: (event)->
        $form = $(event.target)

        $button = $(@lastClicked)
        $button.addClass("loading").attr("disabled", true)
        @$el.removeClass("error")
        @$(".show-when-error").removeClass("error")

        $.ajax({
            method: $form.attr("method")
            url: $form.attr("action")
            data: $form.serialize()
            success: (response, result, xhr)=>
                $button.removeClass("loading").addClass("success")
                # update User.current
                if _.isObject(response)
                    User.current ?= new User(response)
                    User.current.set(response).trigger("sync")

                if document.location.pathname is "/login"
                    # redirect to "/"
                    Backbone.history.navigate("", {trigger: true})

            error: (xhr, result, statusText)=>
                $button.removeClass("loading").removeAttr("disabled")
                @showError(xhr)
        })

        event.preventDefault()
        event.stopPropagation()

    showError: (xhr)->
        response = xhr
        try
            response = JSON.parse(xhr.responseText)
        message = response.message or response.error?.message or response
        
        @$(".show-when-error").attr("data-error", message)
        @$el.addClass("error")
