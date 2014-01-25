BaseModel = require("models/base")

module.exports = class Task extends BaseModel
    # A model that provides its requirePath can be re-instantiated from its url after serialization
    requirePath: module.id
    urlRoot: "/tasks"
    bucket: "tasks"

    # The router consults a model's defaultView and defaultListView to present it
    defaultView: "generic"
    defaultListView: "list"

    # Is this data small enough to reasonably list all items with no query?
    allowListAll: true

    # Define fields with established types to support general-purpose displays and editors
    fields: [
       {
           name: "type",
           type: "string"
       },
       {
           name: "status",
           type: "string"
       }
    ]

    defaults: {
        status: "created"
    }


    index: ->
        index = {
            type: @get("type"),
            status: @get("status")
        }
        return index

    validate: (attributes, options)->
        return null
