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
scriptsRunning = 0
exitCode = 0
shellScript = (source = '')->
    scriptsRunning++
    shell = child_process.spawn('sh', ['-xc', source], {
        stdio: 'inherit'
        env: env
    })
    shell.on("exit", (code, signal)->
        exitCode or= code
        scriptsRunning--
        if scriptsRunning is 0
            process.exit(exitCode)
    )

task 'start', 'Run the server', ->shellScript """
    node server
"""

task 'work', 'Start a worker', ->shellScript """
    server/worker.coffee
"""

task 'develop', 'Run server with auto-reloading', ->shellScript """
    #(sleep 1; open 'http://localhost:#{config.server.port}/') &
    brunch watch --server
"""

task 'build', 'Compile the client', ->shellScript """
    brunch build --production
"""

task 'docs', 'Compile internal documentation', ->
    groc = require("groc")
    groc.LANGUAGES.Dust = {
        nameMatchers: [ '.dust' ],
        pygmentsLexer: 'html',
        multiLineComment: [
            '<!--','','-->',
            '{!','','!}'
        ],
        strictMultiLineEnd: true,
        ignorePrefix: '#',
        foldPrefix: '^'
    }
    groc.LANGUAGES.Stylus = {
        nameMatchers: [ '.styl' ],
        pygmentsLexer: 'sass',
        singleLineComment: ['//'],
        multiLineComment: [ '/*', '*', '*/'],
        ignorePrefix: '}',
        foldPrefix: '^'
    }
    groc.CLI([
        'README.md',
        '{client,server,scripts}/**/*.*',
        '--out','./build/doc'
    ], (->))

task 'docs:upload', 'Compile docs and upload to GitHub-Pages', ->shellScript """
    groc --github README.md '{client,server,scripts}/**/*.*'
"""

# Provide commands for any scripts in the `scripts` directory
for basename in fs.readdirSync("./scripts") then do (basename)->
    filename = "./scripts/#{basename}"
    contents = fs.readFileSync(filename, 'utf8')
    title = basename.replace(/\..*?$/, '')
    # use the first block comment in the file as its description
    description = ''
    for line, i in contents.split(/\r|\n|\r\n/)
        if line.match(/^#!/) then continue
        if line.match(/-\*- mode/) then continue
        if line.match(/^\s*(#|\/\/|$)/)
            description += line.replace(/^\s*(#|\/\/)\s*/, ' ').trim()
            continue
        break

    task(title, description, ->
        # pass command-line arguments directly in to the script
        index = process.argv.indexOf(title)
        args = process.argv.slice(index+1).join(' ')
        script = "#{filename} #{args}"
        shellScript(script)
        # prevent invoking further tasks
        global.invoke = (->)
    )
