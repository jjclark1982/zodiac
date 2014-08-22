# # error-handler.coffee
# ### Directing mistaken traffic

# *This file exports a function that renders the correct error-handler depending on response format and error type.*
# See [HTTP Status Codes](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html)
# ***

# import the node `http` module
http = require("http")

module.exports = (err, req, res, next)->
    # parse the error passed to the function
    switch toString.call(err)
        when "[object Number]"
            status = err
            err = new Error()
            err.status = status
        when "[object String]"
            err = new Error(err)

    # if we have gotten to the error handler without a numeric status, assume 500 Server Error
    # TODO: use err.statusCode here and everywhere else
    if res.statusCode >= 400
        statusCode = res.statusCode

    statusCode ?= err.statusCode
    statusCode ?= err.status
    statusCode ?= 500
    res.statusCode = statusCode

    err.statusCode = statusCode
    err.name = http.STATUS_CODES[err.statusCode] or 'unknown'

    if err.statusCode >= 400
        err.message or= "cannot #{req.method} #{req.path}"

    if req.app.get('env') is 'production'
        err.stack = null

    #return the error in the correct format, with a custom HTML template if appropriate
    res.format({
        json: ->
            try
                errJSON = {
                    statusCode: err.statusCode
                    name: err.name
                    message: err.message
                }
                if err.stack then errJSON.stack = err.stack
                res.json(errJSON)
            catch e
                res.end(err.message)
        html: ->
            if shouldShowLoginPanel(res, req.user)
                # show a login box with error message
                res.locals.flash ?= []
                res.locals.flash.push(err.message)
                res.render("login")
            else
                # show the error with branding and stack trace
                res.render("error", {
                    title: "#{statusCode} #{err.name}"
                    error: err
                })
        default: ->
            res.end(err.message + "\n")
    })

shouldShowLoginPanel = (res, user)->
    if res.xhr
        # partial pages should always show the relevant error
        return false
    if user
        # don't prompt someone to log in if they are already logged in
        # TODO: show a "log in as a different user" button
        return false
    if res.statusCode is 401
        return true
    return false

# ***
# ***NEXT**: Step into [DUST-RENDERER.COFFEE](dust-renderer.html) and observe how it is designed to render tempates, or
# step into [RESOURCE.COFFEE](resource.html) to see how the riak database and middleware factory are set up.
