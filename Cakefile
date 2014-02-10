require 'coffee-script/register'
fs = require 'fs'
path = require 'path'
child_process = require 'child_process'
packageDef = require './package'

# Read in a limited environment from the `.env` file
env = {
    HOME: process.env.HOME
    PATH: "node_modules/.bin:"+process.env.PATH
    NODE_PATH: "client"
}
try
    envText = fs.readFileSync('.env', 'utf8')
    for line in envText.split(/\r\n|\r|\n/)
        match = line.match(/^([^=]+)=(.*)$/)
        if match
            env[match[1]] = match[2] # console.log("#{match[1]}=#{match[2]}")
    process.env = env
catch e
    env = process.env

config = require("./config").config

# Helper function to run a shell script
shellScript = (source = '')-> ->
    shell = child_process.spawn('sh', ['-x'], {
        stdio: ['pipe', process.stdout, process.stderr]
    })
    shell.stdin.end(source)

task 'console', 'Open an interactive prompt', ->
    moduleName = (filename)->
        filename.replace(/\..*?$/, '').replace(/[\W]+(.)?/g, (match, c)->
            c?.toUpperCase() or ""
        )
    repl = require('coffee-script/lib/coffee-script/repl')
    context = repl.start({prompt: "#{packageDef.name}> "}).context
    for file in fs.readdirSync("./server")
        try
            context[moduleName(file)] = require("./server/#{file}")
        catch e
            null

task 'start', 'Run the server', shellScript """
    node server
"""

task 'develop', 'Run server with auto-reloading', shellScript """
    (sleep 1; open 'http://localhost:#{config.server.port}/') &
    brunch watch --server
"""

task 'test', 'Run server-side tests', shellScript """
    mocha --compilers coffee:coffee-script --globals _,Backbone test/test_server.coffee
    # open 'http://localhost:#{config.server.port}/test'
"""

task 'build', 'Compile the client', shellScript """
    brunch build
"""

task 'docs', 'Compile internal documentation', ->
    groc = require("groc")
    groc.LANGUAGES.Dust = {
        nameMatchers: [ '.dust' ],
        pygmentsLexer: 'html',
        multiLineComment: [ '<!--',
            '',
            '-->',
            '{!',
            '',
            '!}' ],
        strictMultiLineEnd: true,
        ignorePrefix: '#',
        foldPrefix: '^'
    }
    groc.CLI(['README.md',
        'server/*',
        'client/{*,*/*,*/*/*}'
        'scripts/*'
    ], (->))

task 'docs:upload', 'Compile internal documentation and upload to GitHub-Pages', shellScript """
    groc --github README.md server/* client/{*,*/*,*/*/*} scripts/*
"""

# Provide commands for any scripts in the `scripts` directory
for basename in fs.readdirSync("./scripts") then do (basename)->
    filename = "./scripts/#{basename}"
    contents = fs.readFileSync(filename, 'utf8')
    title = basename.replace(/\..*?$/, '')
    description = ''
    for line, i in contents.split(/\r|\n|\r\n/)
        if line.match(/^#!/) then continue
        if line.match(/-\*- mode/) then continue
        if line.match(/^\s*(#|\/\/|$)/)
            description += line.replace(/^\s*(#|\/\/)\s*/, ' ').trim()
            continue
        break
    task(title, description, shellScript(filename))
