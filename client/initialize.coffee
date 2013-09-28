require("hydrate-views")
window.router = require("router")

Backbone.history.start({pushState: true, silent: true})

console.log('Client initialized.')
