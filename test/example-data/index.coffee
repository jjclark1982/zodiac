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
        exampleData = require("./"+modelName)
        return new ModelCtor(exampleData)
