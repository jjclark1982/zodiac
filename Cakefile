require 'coffee-script/register'
fs = require 'fs'
path = require 'path'
child_process = require 'child_process'
packageDef = require './package'

# Load environment variables from an `.env` file if it is present
env = process.env
env.PATH = "node_modules/.bin:"+env.PATH
env.NODE_PATH ?= "client"
try
    envText = fs.readFileSync('.env', 'utf8')
    for line in envText.split(/\r\n|\r|\n/)
        match = line.match(/^([^=]+)=(.*)$/)
        if match
            env[match[1]] = match[2] # console.log("#{match[1]}=#{match[2]}")
process.env = env

config = require("./config").config

# Helper function to run a shell script provided as a string
shellScript = (source = '')-> ->
    shell = child_process.spawn('sh', ['-xc', source], {
        stdio: 'inherit'
        env: env
    })
    shell.on("exit", (code, signal)->
        process.exit(code)
    )

task 'start', 'Run the server', shellScript """
    node server
"""

task 'work', 'Start a worker', shellScript """
    server/task-worker.coffee
"""

task 'develop', 'Run server with auto-reloading', shellScript """
    (sleep 1; open 'http://localhost:#{config.server.port}/') &
    brunch watch --server
"""

task 'test', 'Run server-side tests', shellScript """
    mocha --compilers coffee:coffee-script/register --globals _,Backbone test/test_server.coffee
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
