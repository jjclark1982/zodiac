BaseModel = require("lib/model")

module.exports = class BackgroundJob extends BaseModel
    # A model that provides its requirePath can be re-instantiated from its url after serialization
    requirePath: module.id
    urlRoot: "/background-jobs"
    bucket: "background-jobs"

    # The router consults a model's defaultView and defaultListView to present it
    defaultView: "form"
    defaultListView: "table"

    # Is this data small enough to reasonably list all items with no query?
    allowListAll: true

    # Define fields with established types to support general-purpose displays and editors
    fields: [
       {
           name: "name",
           type: "text"
       },
       {
           name: "type",
           type: "readonly"
       },
       {
           name: "status",
           type: "readonly"
       }
    ]

    defaults: {
        status: "NEW"
    }


    index: ->
        index = {
            type: @get("type"),
            status: @get("status")
        }
        return index

    validate: (attributes, options)->
        return null
