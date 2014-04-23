BaseModel = require("base/model")

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
            if "admin" in (editor.permissions or [])
                return null
            if "permissions" of @changed
                return "You are not allowed to edit permissions"
            if editor.username isnt @id
                return "You are not permitted to edit this user"
        return null

if window?
    User.current = User.loadFromUrl("/users/me")
