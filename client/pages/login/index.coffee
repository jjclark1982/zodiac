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
        "click .dismiss-button": "disappear"
        "transitionend": "transitionEnd"
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

                if this is LoginView.currentModal
                    LoginView.currentModal = null
                    @disappear()
                    return

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

    appear: ->
        _.defer(=>
            @$el.removeClass("hidden")
        )

    disappear: ->
        @$el.addClass("hidden")
        # will lead to transitionEnd

    transitionEnd: (event)->
        if (event.target is @el) and @$el.hasClass("hidden")
            @remove()

LoginView.currentModal = null
LoginView.showModal = (xhr)->
    return if document.location.pathname is "/login"
    return if LoginView.currentModal

    modal = new LoginView({className: "login-view modal hidden"})
    modal.render(->
        modal.showError(xhr)
    )
    $(document.body).append(modal.el)
    modal.appear()
    LoginView.currentModal = modal

registeredYet = false
LoginView.showWhenUnauthorized = ->
    return if registeredYet
    registeredYet = true
    # a "401 unauthorized" response usually results from some backbone sync
    # and usually contains some specific message.
    # we want to show that message and pop up this form when appropriate.
    
    # listening to all ajaxErrors is a simple way to detect relevant 401s
    $(document).bind("ajaxError", (event, xhr, request, statusText)->
        if request.url[0] is "/" and xhr.status is 401
            LoginView.showModal(xhr)
    )

# TODO: redirect or reload HTML 401 pages (except when xhr partial)
