#!/usr/bin/env mocha --compilers coffee:coffee-script/register --globals _,Backbone

# Run server-side tests

chai = require("chai")
expect = chai.expect
fs = require ("fs")
path = require ("path")
coffeelint = require("coffeelint")
lintConfig = require("../config.coffee").config.plugins.coffeelint.options
child_process = require 'child_process'

walk = (dir) ->
    results = []
    list = fs.readdirSync(dir)
    for file in list
        file = dir + "/" + file
        stat = fs.statSync(file)
        if stat and stat.isDirectory()
            results = results.concat(walk(file))
        else
            results.push(file)
    return results

serverDir = path.join(__dirname, '..', 'server')
serverFiles = walk(serverDir)
serverSourceFiles = (file for file in serverFiles when !file.match(/\/test\.coffee$/))
serverTestFiles = (file for file in serverFiles when file.match(/\/test\.coffee$/))

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

describe 'Server', ->
    describe "should lint without errors", ->
        for file in serverSourceFiles when file.match(/\.coffee$/) then do (file)->
            it file, (done)->
                fs.readFile(file, (fileErr, data)->
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
            
    describe 'should compile server unit tests without errors', ->
        for name in serverTestFiles then do (name)->
            it name, ->
                require(name)

    server = null
    it 'should compile without errors', ->
        server = require('../server')

    it 'should start without errors', (done)->
        server.startServer(0, null, (startedServer)->
            process.env.PORT = server.address().port
            # publish the PORT so that other tests in this process can connect to the right server
            done()
        )


describe 'Client', ->
    it 'should compile without errors', (done)->
        @timeout(5000)
        
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

    it 'should run frontend tests in phantomjs', (done)->
        @timeout(5000)
        phantom = child_process.spawn("mocha-phantomjs", [
            "--reporter", "json-stream"
            "http://localhost:#{process.env.PORT}/test"
        ])
        frontendSuites = {}
        phantom.stdout.on("data", (chunks)->
            for chunk in chunks.toString().split(/\n/) when chunk
                try
                    result = JSON.parse(chunk)
                    type = result[0]
                    clientTest = result[1]
                    switch type
                        when 'start', 'end'
                            null
                        when 'pass', 'fail'
                            suiteName = clientTest.fullTitle.replace(clientTest.title, '')
                            frontendSuites[suiteName] ?= []
                            frontendSuites[suiteName].push(result)
                        else
                            throw new Error("unrecognized json-stream output")
                catch e
                    # unparseable output might not be an error. display it.
                    console.error(chunk)
        )
        phantom.on("exit", (code, signal)->
            describe "Frontend Tests", ->
                for suiteName, suite of frontendSuites
                    describe suiteName, ->
                        for result in (suite or []) then do (result)->
                            title = result[1].title
                            if result[1].duration > 10
                                title += " (#{result[1].duration}ms)"
                            it title, ->
                                expect(result[0]).to.equal("pass")

            expect(code).to.equal(0)
            done()
        )
