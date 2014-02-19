BaseModel = require("base/model")

module.exports = class User extends BaseModel
    requirePath: module.id
    urlRoot: "/users"
    bucket: "users"

    idAttribute: 'username'

    fields: [
        {
           name: "username",
           type: "readonly"
        },
        {
           name: "password",
           type: "password"
        },
        {
           name: "email",
           type: "string"
        },
        {
           name: "permissions",
           type: "array"
        }
    ]

    # links: {
    #     cart: {
    #         type: 'hasOne'
    #         target: 'cart'
    #     }
    # }

    allowListAll: true
    
    index: ->
        { all: '1' }

    validate: (attributes, options)->
        return null

if window?
    currentUser = new User()
    currentUser.url = '/users/me'
    module.exports.current = currentUser
    currentUser.fetch()
