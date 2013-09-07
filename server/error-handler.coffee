http = require("http")

module.exports = (err, req, res, next)->
    switch toString.call(err)
        when "[object Number]"
            status = err
            err = new Error()
            err.status = status
        when "[object String]"
            err = new Error(err)

    err.status or= 500
    err.name = http.STATUS_CODES[err.status] or 'unknown'

    if err.status >= 400
        err.message or= "cannot #{req.method} #{req.path}"

    res.statusCode = err.status

    if req.app.get('env') is 'production'
        delete err.stack

    res.format({
        json: ->
            res.json(err)
        html: ->
            res.render('error', {title: "#{err.status} #{err.name}", error: err})
        default: ->
            res.end(err.message)
    })

