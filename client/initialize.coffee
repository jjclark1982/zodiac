require("models/user")
require("hydrate-views")

Router = require("router")
window.router = new Router()
# Start the router silently because the current view should already be in the received html
Backbone.history.start({pushState: true, silent: true})

console.log('Client initialized.')
