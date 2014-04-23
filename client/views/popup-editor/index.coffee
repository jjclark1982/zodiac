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

# This helper function lets any view spawn an editor based on an event of its choice.
# The event should be bound to some element that has a "data-editable-field" attribute.
# Usage:
# events: -> {
#     "dblclick [data-editable-field]": require("views/popup-editor").showEditor
# }
PopupEditorView.showEditor = (event)->
    view = this # set by Backbone event delegation
    fieldName = $(event.currentTarget).data("editable-field")
    return unless view.model and fieldName

    # for nested editable fields such as an image background,
    # only edit the topmost one
    event.stopPropagation()

    # undo the selection caused by the doubleclick
    selection = window.getSelection?() or document.selection
    selection?.empty?() or selection?.removeAllRanges?()

    popup = new PopupEditorView({
        model: view.model
        fieldName: fieldName
        location: {x: event.pageX, y: event.pageY}
    })
    $(document.body).append(popup.el)
    popup.render()
