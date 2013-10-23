BaseModel = require("./base")

module.exports = class User extends BaseModel
    requirePath: module.id
    urlRoot: "/users"
    bucket: "users"

    fields: {
        name: String
        permissions: [String]        
    }
    
    validate: (attributes, options)->
        return null
