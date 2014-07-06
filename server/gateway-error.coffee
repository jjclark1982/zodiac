gatewayError = (dbErr)->
    if dbErr.code is 'ETIMEDOUT' or dbErr.syscall is 'connect'
        statusCode = 504
        name = "GatewayError"
        message = "Unable to connect to database"
    else if dbErr.statusCode is 500 or !dbErr.statusCode?
        statusCode = 502
        name = "DatabaseError"
        message = dbErr.message
    else
        # this error already has useful information such as 401, 403, etc
        return dbErr

    err = new Error(message)
    err.statusCode = statusCode
    if name
        err.name = name

    err.stack = err.stack + "From previous " + dbErr.stack
    return err

module.exports = gatewayError
