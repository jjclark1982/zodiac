# Exports a hash of all defined models
# Usage:
# modelType = "user"
# ModelCtor = require("models")[modelType]

models = {}

if window?
    for name in window.require.list() when name.match(/^models\//)
        continue if name is 'models/index'

        modelName = name.replace(/.*\//, '')
        models[modelName] = require("models/"+modelName)

else
    fs = require("fs")
    modelFiles = fs.readdirSync(__dirname)
    for filename in modelFiles
        continue if filename is 'index.coffee'

        modelName = filename.replace(/\..*$/, '')
        continue unless filename # ignore dotfiles
        models[modelName] = require("models/"+modelName)

module.exports = models
