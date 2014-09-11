dust = require("dustjs-linkedin")
require("./dust-renderer")

# retain whitespace when compiling this markdown template
oldFormat = dust.optimizers.format
dust.optimizers.format = (ctx, node)->node
template = require("./layouts/blueprint")
dust.optimizers.format = oldFormat
require("lib/dust-helpers")
require("../test/example-data")

# construct a list of model definitions
modelDefs = []
for modelName, ModelCtor of require("models") when ModelCtor.prototype.urlRoot
    example = new ModelCtor()
    example.set(example.titleAttribute, "Example #{ModelCtor.name}")
    example.set(example.idAttribute, "example")
    try
        example = ModelCtor.loadExample()

    example2 = example.clone()
    example2.set(example2.titleAttribute, "Different #{ModelCtor.name}")
    example2.set(example2.idAttribute, "example2")

    exampleNew = example.clone()
    exampleNew.unset(exampleNew.idAttribute)

    modelDef = {
        modelName: ModelCtor.name
        proto: ModelCtor.prototype
        example: example
        example2: example2
        exampleNew: exampleNew
    }
    modelDefs.push(modelDef)

context = {
    host: "http://"+require("os").hostname()+":"+process.env.PORT+"/"
    packageDef: (require("../package"))
    modelDefs: modelDefs
}

# export a middleware
module.exports = (req, res, next)->
    template.render(context, (err, text)->
        if err then return next(err)
        
        res.set({"Content-Type": "text/x-markdown"})
        res.send(text)

        if process.env.NODE_ENV is 'development'
            template.reload()
    )
