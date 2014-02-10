BaseModel = require("base/model")

module.exports = class Query extends BaseModel
    requirePath: module.id

    parse: (response, options)->
        attrs = response
        if _.isString(response)
            attrs = {}
            for keyval in response.replace(/^\?/,'').split(/&/)
                parts = keyval.split("=")
                if parts.length >= 2
                    key = decodeURIComponent(parts[0]).replace(/\+/g, "%20")
                    val = decodeURIComponent(parts[1]).replace(/\+/g, "%20")
                    attrs[key] = val
        return attrs

    serialize: ->
        str = (for key, val of @attributes
            encodeURIComponent(key) + '=' + encodeURIComponent(val)
        ).join('&')
        return str
