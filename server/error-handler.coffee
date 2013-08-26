http = require("http")

module.exports = (err, req, res, next)->
    switch toString.call(err)
        when "[object Number]"
            status = err
            err = new Error()
            err.status = status
        when "[object String]"
            err = new Error(err)

    if (err.status) then res.statusCode = err.status
    if (res.statusCode < 400) then res.statusCode = 500
    err.name = http.STATUS_CODES[res.statusCode]
    err.message or= "cannot #{req.method} #{req.path}"

    if req.app.get('env') is 'production'
        delete err.stack

    res.render('error', {title: "#{err.status} #{err.name}", error: err})
    return
