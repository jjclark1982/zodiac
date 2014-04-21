BaseView = require("base/view")

module.exports = class PopupEditorView extends BaseView
    # A view that provides its requirePath can be re-instantiated after serialization
    requirePath: module.id

    # The CSS class for this view
    className: "popup-editor-view"

    # BaseView's `render()` function uses the subclass's provided template
    template: require("./template")

    initialize: (options)->
        window.pe = @
        @location = options.location or {x: 0, y: 0}
        @fieldName = options.fieldName
        @listenTo(@, "render:after", ->
            @$el.css({
                left: @location.x
                top: @location.y
            })
        )

    events: {
        "click .save-button": "save"
        "click .cancel-button": "cancel"
        "mousedown": "dragStart"
    }

    save: (event)->
        $(event.target).attr("disabled", true)
        @model.save(null, {
            success: =>
                @remove()
            error: =>
                $(event.target).removeAttr("disabled").css({background: "red"})
                # TODO: report the actual error to the user
        })

    cancel: (event)->
        @model.fetch()
        @remove()

    dragStart: (event)->
        if $(event.target).is(".popup-editor-view,.label-text")
            event.preventDefault()
            @dragStart = {
                x: event.pageX
                y: event.pageY
            }
            $(window).on("mousemove", @drag)
            $(window).on("mouseup", @dragEnd)

    drag: (event)=>
        if @dragStart
            @$el.css({
                left: @location.x + (event.pageX - @dragStart.x)
                top: @location.y + (event.pageY - @dragStart.y)
            })

    dragEnd: (event)=>
        @location = {
            x: @location.x + (event.pageX - @dragStart.x)
            y: @location.y + (event.pageY - @dragStart.y)
        }
        $(window).off("mousemove", @drag)
        $(window).off("mouseup", @dragEnd)
        @dragStart = null
