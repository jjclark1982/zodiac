models = require("models")

for modelName, ModelCtor of models then do (modelName, ModelCtor)->
    ModelCtor.loadExample = ->
        exampleData = require("./"+modelName)
        return new ModelCtor(exampleData)
