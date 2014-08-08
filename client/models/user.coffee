BaseModel = require("lib/model")

module.exports = class User extends BaseModel
    requirePath: module.id
    urlRoot: "/users"
    bucket: "users"
    
    idAttribute: 'username'
    titleAttribute: 'username'
    
    fields: [
        {
            name: "username",
            type: "id"
        },
        {
            name: "password",
            type: "password"
        },
        {
            name: "email",
            type: "text"
        },
        {
            name: "permissions",
            type: "object"
        }
        # {
        #     name: "cart",
        #     type: "link",
        #     target: "cart",
        #     multiple: false
        # }
    ]
    
    index: ->
        return {
            all: '1'
        }

    validate: (attributes, options)->
        editor = options.editor
        if editor
            if editor.hasPermission("admin")
                return null
            if "permissions" of @changed
                return "You are not allowed to edit permissions"
            if editor.id isnt @id
                return "You are not permitted to edit this user"
        return null

    hasPermission: (permission)->
        return (permission in (@get("permissions") or []))
