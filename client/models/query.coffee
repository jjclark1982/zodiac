BaseModel = require("base/model")

encode = (str)->
    return encodeURIComponent(str).replace(/%20/g, '+')

decode = (str)->
    return decodeURIComponent(str.replace(/\+/g, "%20"))

module.exports = class Query extends BaseModel
    requirePath: module.id

    parse: (response, options)->
        attrs = response
        if _.isString(response)
            attrs = {}
            for keyval in response.replace(/^.*\?/,'').split(/&/)
                parts = keyval.split("=")
                if parts.length >= 2
                    key = decode(parts[0])
                    val = decode(parts[1])

                    if attrs[key]
                        unless _.isArray(attrs[key])
                            attrs[key] = [attrs[key]]
                        attrs[key].push(val)
                    else
                        attrs[key] = val
        return attrs

    toString: ->
        pairs = []
        for key, vals of @attributes
            unless _.isArray(vals)
                vals = [vals]
            for val in vals
                pairs.push(encode(key) + '=' + encode(val))
        return pairs.join('&')
