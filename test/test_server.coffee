chai = require("chai")
expect = chai.expect
fs = require ("fs")
path = require ("path")
coffeelint = require("coffeelint")
lintConfig = require("../config.coffee").config.plugins.coffeelint.options
child_process = require 'child_process'

serverDir = path.join(__dirname, '..', 'server')
serverFiles = fs.readdirSync(serverDir)

process.env.SILENT = true

describe('Database', ->
    it('should connect without errors', (done)->
        db = require('../server/db')
        db.ping((err, isAlive)->
            if err
                return done(err)
            if !isAlive
                return done(new Error("Unable to establish connection to riak server"  + process.env.RIAK_SERVERS))
            else
                return done()
        )
    )
)

describe('Server', ->
    describe("should lint without errors", ->
        for file in serverFiles when file.match(/\.coffee$/) then do (file)->
            it(file, (done)->
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

    it 'should start without errors', (done)->
        server.startServer(0, null, (startedServer)->
            done()
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
        
        brunch = require('brunch')
        brunchLogger = require("brunch/node_modules/loggy")

        # silence brunch, but use its error logger to report errors to mocha
        errorLogger = brunchLogger.error
        brunchLogger.error = ->
            errorLogger.apply(arguments)
            done(new Error(arguments[0]))
        brunchLogger.log = (->)
        brunchLogger.info = (->)
        brunchLogger.warn = (->)

        brunch.build({}, (compiledFiles)->
            expect(compiledFiles).to.be.ok
            done()
        )
    )
    it 'should pass all tests in test_client', (done)->
        phantom = child_process.spawn("mocha-phantomjs", ["http://localhost:#{process.env.PORT}/test"], {
        stdio: 'inherit'
        })
        phantom.on("exit", (code, signal)->
            expect(code).to.be.equal(0)
            done()
        )
)
