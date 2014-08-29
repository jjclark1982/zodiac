# Widget that shows icons, animations, and messages for standard Backbone events:
#
#     - request: spinning wheel icon
#     - invalid (or 403 error): orange warning sign icon with message
#     - error (or timeout, hopefully): red warning sign icon with message
#     - success: fading green checkmark icon
#
# Usage:
#
#     {>activity-indicator model=model /}
#
#     {>activity-indicator collection=collection /}
#

BaseView = require("lib/view")

module.exports = class StatusIndicatorView extends BaseView
    # A view that provides its requirePath can be re-instantiated after serialization
    requirePath: module.id

    # The CSS class for this view
    className: "status-indicator-view"

    # BaseView's `render()` function uses the subclass's provided template
    template: require("./template")

    # This runs once every time a view is instantiated 
    initialize: (options)->
        return this

    # This runs once when a view is instantiated with a working DOM element
    hydrate: ->
        @listenToStandardEvents(@model)
        @listenToStandardEvents(@collection)

    listenToStandardEvents: (object)->
        return unless object

        @listenTo(object, "request", (target, xhr, options)->
            # when fetching a single model inside a collection, we get request and sync events for both
            # so we check the target object to make sure we are only showing relevant events
            return unless target is object
            @$el.removeClass("error invalid success").addClass("loading")
            @$("[data-message]").removeAttr("data-message")
        )

        @listenTo(object, "invalid", (target, error, options)->
            return unless target is object
            @$el.removeClass("loading").addClass("invalid")
            @$(".show-when-invalid").attr("data-message", error)
            # TODO: standardize field-specific validation error structure, and support structured errors
        )

        @listenTo(object, "error", (target, xhr, options)->
            return unless target is object
            if xhr.status is 403
                object.trigger("invalid", object, getErrorMessage(xhr), options)
            else
                @$el.removeClass("loading").addClass("error")
                @$(".show-when-error").attr("data-message", getErrorMessage(xhr))
        )

        @listenTo(object, "sync", (target, response, options)->
            return unless target is object
            # TODO: avoid showing success for the very first GET

            @$el.removeClass("loading").addClass("success")
            # if animation is not supported, fall back to non-animated removal
            @removeSuccessTimeout = setTimeout(=>
                @$el.removeClass("success")
                @removeSuccessTimeout = null
            , 500)

            # update the data-model-url if it has changed
            if target is @model
                @$el.attr("data-model-url", _.result(object, "url"))
        )

    events: {
        "webkitAnimationStart": "animationStart"
        "mozAnimationStart":    "animationStart"
        "msAnimationStart":     "animationStart"
        "oanimationstart":      "animationStart"
        "animationstart":       "animationStart"
        "webkitAnimationEnd":   "animationEnd"
        "mozAnimationEnd":      "animationEnd"
        "msAnimationEnd":       "animationEnd"
        "oanimationend":        "animationEnd"
        "animationend":         "animationEnd"
    }

    animationStart: (event)->
        if @removeSuccessTimeout
            clearTimeout(@removeSuccessTimeout)
            @removeSuccessTimeout = null

    animationEnd: (event)->
        if $(event.target).hasClass("show-when-success")
            @$el.removeClass("success")
        

getErrorMessage = (xhr={})->
    response = xhr.responseText or xhr
    try
        response = JSON.parse(xhr.responseText)
    message = response.message or response.error?.message or response
    return message or ""

getErrorCode = (xhr)->
    return "" unless xhr
    string = "#{xhr.status} #{xhr.statusText}"
