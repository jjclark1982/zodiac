chai = require 'chai'
expect = chai.expect
fs = require 'fs'
path = require 'path'
coffeelint = require 'coffeelint'
lintConfig = require("../config.coffee").config.plugins.coffeelint.options

serverDir = path.join(__dirname, '..', 'server')
serverFiles = fs.readdirSync(serverDir)

describe('Server', ->
    for file in serverFiles when file.match(/\.coffee$/)
        do (file)->describe('/'+file, ->
            it('should lint without errors', (done)->
                fs.readFile(path.join(serverDir, file), (fileErr, data)->
                    if fileErr
                        return done(fileErr)

                    lintResults = coffeelint.lint(data.toString(), lintConfig)

                    errors = []
                    for item in lintResults
                        error = new Error(item.context)
                        error.name = item.message
                        error.stack = "#{error.toString()}\n    at #{file}:#{item.lineNumber}\n    >#{item.line}"
                        if item.level is 'error'
                            errors.push(error)
                        else
                            console.error("Lint warning: ", error.stack)

                    if errors.length > 1
                        multiError = new Error()
                        multiError.stack = (e.stack for e in errors).join("\n\n")
                        done(multiError)
                    else if errors.length is 1
                        done(errors[0])
                    else
                        done()
                )
            )
        )

    server = null
    it('should compile without errors', ->
        server = require('../server')
    )

    it('should start without errors', (done)->
        server.startServer(0, null, (startedServer)->
            done()
        )
    )

    makeRequest = (options = {}, callback)->
        if toString.call(options) is "[object String]"
            options = {path: options}
        options.hostname ?= 'localhost'
        options.port ?= server.address().port
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

    it('should serve a landing page with status 200', (done)->
        makeRequest('/', (err, res)->
            if err
                return done(err)

            if res.statusCode is 200
                done()
            else
                done(new Error("#{res.statusCode} #{res.title}"))
        )
    )
)

describe('Client', ->
    it('should compile without errors', (done)->
        this.timeout(5000)
        
        brunchLogger = require("brunch/node_modules/loggy")
        errorLogger = brunchLogger.error
        brunchLogger.error = ->
            errorLogger.apply(arguments)
            done(new Error(arguments[0]))

        brunch = require 'brunch'; w = brunch.build({}, (compiledFiles)->
            expect(compiledFiles).to.be.ok
            done()
        )
    )
)
