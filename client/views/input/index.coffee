BaseView = require("base/view")

typeMap = {
    'longtext': 'textarea'
    'html': 'textarea'
    'object': 'json'
    'string': 'text' # TODO: fix these in model defs
}

module.exports = class InputView extends BaseView
    # A view that provides its requirePath can be re-instantiated after serialization
    requirePath: module.id

    # The CSS class for this view
    className: "input-view"
    tagName: "label"

    template: require("./template")

    initialize: (options)->
        @showLabel = options.showLabel

        if options.name
            @field = @model.fieldDefs()[options.name] or {
                name: options.name
                type: options.type
            }
        else if options.field
            @field = options.field
        else
            throw new Error("Cannot initialize InputView without a valid field definition")

        # populate the initial HTML with the current value
        @value = options.value ? @model.get(@field.name)

        @type = options.type or typeMap[@field.type] or @field.type
        if @type is 'link'
            @value = @model.getLink(@field.name)

    hydrate: ->
        # don't set classes from common events as we expect a superview to handle that
        return this

    attributes: ->
        atts = super(arguments...)
        if @field
            atts["data-name"] = @field.name
        return atts

    bindings: ->
        if @type is 'json'
            return {
                "[name]": {
                    observe: @field.name
                    onGet: (data)->
                        JSON.stringify(data)
                    onSet: (input)->
                        JSON.parse(input) #throws errors
                }
            }
        else
            return {
                "[name]": @field.name
            }
