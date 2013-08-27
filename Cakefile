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
        if require.extensions[path.extname(file)]
            context[moduleName(file)] = require("./server/#{file}")

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

task 'docs', 'Compile internal documentation', shellScript """
    docco server/* client/{*,*/*}.coffee
"""

task 'build', 'Compile the client', shellScript """
    brunch build
"""

task 'test', 'Run tests', shellScript """
    mocha --compilers coffee:coffee-script --globals _,Backbone test/test_server.coffee
    # open 'http://localhost:#{require("./config").config.server.port}/test'
"""

task 'start', 'Run the server', shellScript """
    node server
"""

task 'develop', 'Run server with auto-reloading', shellScript """
    (sleep 1; open 'http://localhost:#{require("./config").config.server.port}/') &
    brunch watch --server
"""
