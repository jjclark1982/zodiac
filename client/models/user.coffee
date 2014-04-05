BaseModel = require("base/model")

module.exports = class User extends BaseModel
    requirePath: module.id
    urlRoot: "/users"
    bucket: "users"
    
    idAttribute: 'username'
    
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
            type: ["text"]
        }
        # {
        #     name: "cart",
        #     type: "link",
        #     target: "cart"
        # }
    ]
    
    index: ->
        { all: '1' }

    validate: (attributes, options)->
        return null

if window?
    currentUser = new User()
    currentUser.url = '/users/me'
    module.exports.current = currentUser
    currentUser.fetch()
