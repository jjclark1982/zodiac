BaseModel = require("./base")

module.exports = class User extends BaseModel
    requirePath: module.id
    urlRoot: "/users"
    bucket: "users"

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

    links: {
        cart: {
            type: 'hasOne'
            target: 'cart'
        }
    }

    allowListAll: true

    validate: (attributes, options)->
        return null

    addBookmark: (activity) ->
        currentBookmarks = @get("bookmarks") or {}
        currentBookmarks[activity.id] = true
        @set("bookmarks", currentBookmarks)
        @save()

    removeBookmark: (activity) ->
        currentBookmarks = @get("bookmarks") or {}
        delete currentBookmarks[activity.id]
        @set("bookmarks", currentBookmarks)
        @save()

    hasBookmark: (activity)->
        currentBookmarks = @get("bookmarks") or {}
        return !! currentBookmarks[activity.id]

currentUser = new User()
currentUser.url = '/users/me'
module.exports.current = currentUser

if window?
    currentUser.fetch()
