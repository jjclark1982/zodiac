BaseModel = require("./base")

module.exports = class User extends BaseModel
    requirePath: module.id
    urlRoot: "/users"
    bucket: "users"
    idAttribute: "username"

    fields: {
        username: String
        email: String
        permissions: [String]
    }

    links: {
        cart: {
            type: 'hasOne'
            target: 'cart'
        }
    }

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
