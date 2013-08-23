fs = require 'fs'
path = require 'path'
child_process = require 'child_process'
packageDef = require './package'

# Read in a limited environment from the `.env` file
env = {
    HOME: process.env.HOME
    PATH: "node_modules/.bin:"+process.env.PATH
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

task 'clean', 'Remove built and managed files', shellScript """
    rm -rf docs
    rm -rf build
    rm -rf bower_components
    rm -rf node_modules
"""

task 'install', 'Install dependencies', shellScript """
    # this script is normally run by `npm install`
    # if NPM hasn't been run yet, run it now
    if [ ! -e "./node_modules/" ]; then
        exec npm install
    fi

    # compile docs
    [ -x "$(which docco)" ] && docco -e .coffee Cakefile server/*

    # install sass on production
    if [ ! -x "$(which sass)" -a "$(uname)" != "Darwin" ]; then
        export GEM_HOME="${HOME}/.ruby_gems"
        gem install --bindir "bin" --no-rdoc --no-ri sass
    fi

    # install bower components
    bower install

    # build the production client
    brunch build --optimize
"""

task 'test', 'Run tests', shellScript """
    mocha --compilers coffee:coffee-script --globals _,Backbone,Handlebars test/test_server.coffee
"""

task 'develop', 'Run server with original code and auto-reloading', shellScript """
    (sleep 1; open http://localhost:#{env.PORT}/) &
    brunch watch --server
"""

task 'deploy', 'Minify the client and run the server', shellScript """
    brunch build --optimize
    node server
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
