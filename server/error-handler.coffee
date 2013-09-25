# # error-handler.coffee
# ### Directing mistaken traffic

# *This file exports a function that renders the correct error-handler depending on response format and error type.*
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

    err.status or= 500
    err.name = http.STATUS_CODES[err.status] or 'unknown'

    if err.status >= 400
        err.message or= "cannot #{req.method} #{req.path}"

    res.statusCode = err.status

    if req.app.get('env') is 'production'
        delete err.stack

    #return the error in the correct format, with a custom HTML template if appropriate
    res.format({
        json: ->
            res.json(err)
        html: ->
            res.render('error', {title: "#{err.status} #{err.name}", error: err})
        default: ->
            res.end(err.message)
    })

# ***
# ***NEXT**: Step into [DUST-RENDERER.COFFEE](dust-renderer.html) and observe how it is designed to render tempates, or
# step into [RESOURCE.COFFEE](resource.html) to see how the riak database and middleware factory are set up.
