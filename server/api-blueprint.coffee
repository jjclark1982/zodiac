dust = require("dustjs-linkedin")
require("./dust-renderer")

# retain whitespace when compiling this markdown template
oldFormat = dust.optimizers.format
dust.optimizers.format = (ctx, node)->node
template = require("./layouts/blueprint")
dust.optimizers.format = oldFormat
require("lib/dust-helpers")

# construct a hash of ModelName: modelPrototype
modelProtos = {}
for key, val of require("models") when val.prototype.urlRoot
    modelProtos[val.name] = val.prototype
context = {
    host: "http://"+require("os").hostname()+":"+process.env.PORT+"/"
    packageDef: (require("../package"))
    modelProtos: modelProtos
}

# export a middleware
module.exports = (req, res, next)->
    template.render(context, (err, text)->
        if err then return next(err)
        
        res.set({"Content-Type": "text/x-markdown"})
        res.send(text)
    )

