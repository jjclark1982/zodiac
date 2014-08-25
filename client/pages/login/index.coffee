BaseView = require("lib/view")
User = require("models/user")

module.exports = class LoginView extends BaseView
    # A view that provides its requirePath can be re-instantiated after serialization
    requirePath: module.id

    # The CSS class for this view
    className: "login-view"

    # BaseView's `render()` function uses the subclass's provided template
    template: require("./template")

    title: "Log In"

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
                    # TODO: parse data and set metadata

                if @isModal
                    @disappear()
                    return

                if window.location.pathname is "/login"
                    # when showing a login view at the normal loc, redirect to "/"
                    Backbone.history.navigate("", {trigger: true})
                else
                    # when showing a login view at another page, reload to get the real page
                    window.location.reload(true)
                    # it may be possible to use the router for this, if we had some way
                    # to bypass its cache of poppable views
                    # link = document.createElement("a")
                    # link.href = document.location.href
                    # if window.router.navigateToLink(link, {trigger: true, replace: true})
                    #     return

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
        LoginView.currentModal = null
        @$el.addClass("hidden")
        # will lead to transitionEnd

    transitionEnd: (event)->
        if (event.target is @el) and @$el.hasClass("hidden")
            @remove()

LoginView.currentModal = null
LoginView.showModal = (xhr)->
    return if LoginView.currentModal
    return if $(".login-view").length > 0 # avoid showing multiple logins for any reason

    modal = new LoginView({className: "login-view modal hidden"})
    modal.isModal = true
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

# TODO: refactor modal display with that in lightbox, toward reusing animations and dismissal events
