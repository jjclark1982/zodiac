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

        if window?
            @listenTo(@model, "change:#{@field.name}", @modelChanged)

    attributes: ->
        atts = super(arguments...)
        if @field
            atts["data-name"] = @field.name
        return atts

    events: {
        "keyup *": "domChanged"
        "change *": "domChanged"
    }

    modelChanged: (model, value, options)->
        @value = value
        @$input ?= @$("[name='#{@field.name}']")
        switch @type
            when 'link'
                @value = @model.getLink(@field.name)
            when 'boolean'
                @$input[0]?.checked = !!@value
            when 'json'
                try
                    @value = JSON.stringify(@value)
                    @$input.val(@value) unless @$input.val() is @value
            else
                @$input.val(@value) unless @$input.val() is @value

    domChanged: _.debounce((event)->
        $input = $(event.target)
        switch @type
            when 'number'
                value = parseFloat($input.val())
            when 'boolean'
                value = $input.is(":checked")
            when 'json'
                try
                    value = JSON.parse($input.val())
                catch e
                    @model.trigger('invalid', @model, e)
                    return
            else
                value = $input.val()
        @model.set(@field.name, value)
    , 30)
