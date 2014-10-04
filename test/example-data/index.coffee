models = require("models")

# Inject a `loadExample()` class method into each model constructor,
# that instantiates a model with example data from this folder.
# 
# Usage:
#     require("example-data")
#     User = require("models/user")
#     exampleUser = User.loadExample()

mockGetLink = (linkName)->
    linkDef = @fieldDefs()[linkName]
    return undefined unless linkDef

    TargetCtor = require("models/"+linkDef.target)
    if linkDef.multiple
        target = new Backbone.Collection([], {model: TargetCtor})
        target.url = _.result(@, 'url') + "/" + linkName
        target._exampleData = []

    else
        target = TargetCtor.loadExample()

    @_linkedModels ?= {}
    @_linkedModels[linkName] = target
    return target

for modelName, ModelCtor of models then do (modelName, ModelCtor)->
    ModelCtor.loadExample = ->
        exampleData = _.clone(require("./"+modelName))
        model = new ModelCtor(exampleData, {parse: true})
        model._exampleData = exampleData
        model.getLink = mockGetLink
        return model
