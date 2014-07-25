require("lib/backbone-sync-metadata")
User = require("models/user")
User.current = User.loadFromUrl("/users/me")

require("lib/hydrate-views")

Router = require("lib/router")
window.router = new Router()
# Start the router silently because the current view should already be in the received html
Backbone.history.start({pushState: true, silent: true})

console.log('Client initialized.')
