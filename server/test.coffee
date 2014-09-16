makeRequest = (options = {}, callback)->
    # TODO: use 'request' library for this
    if toString.call(options) is "[object String]"
        options = {path: options}
    options.hostname ?= 'localhost'
    options.port ?= process.env.PORT
    options.method ?= 'GET'

    http = require("http")
    req = http.request(options, (res)->
        res.body = ''
        res.on('data', (chunk)->
            res.body += chunk
        )
        res.on('end', ->
            if res.headers['content-type']?.match('text/html')
                match = res.body.match(/<title>(.*?)<\/title>/)
                res.title = match?[1]
            res.title or= res.body.split(/[\r\n]/)[0]
            callback(null, res)
        )
    )
    req.on('error', callback)
    req.end()

describe 'Web Server', ->
    it 'should serve a landing page with status 200', (done)->
        makeRequest('/', (err, res)->
            if err
                return done(err)

            if res.statusCode is 200
                done()
            else
                done(new Error("#{res.statusCode} #{res.title}"))
        )
