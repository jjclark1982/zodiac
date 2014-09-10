models = require("models")

# Inject a `loadExample()` class method into each model constructor,
# that instantiates a model with example data from this folder.
# 
# Usage:
#     require("example-data")
#     User = require("models/user")
#     exampleUser = User.loadExample()

for modelName, ModelCtor of models then do (modelName, ModelCtor)->
    ModelCtor.loadExample = ->
        exampleData = _.clone(require("./"+modelName))
        model = new ModelCtor(exampleData, {parse: true})
        model._exampleData = exampleData
        return model
