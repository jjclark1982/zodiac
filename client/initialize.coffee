LoginView = require("pages/login")
LoginView.showWhenUnauthorized()

User = require("models/user")
User.current = User.loadFromUrl("/users/me") # may lead to a 401 and associated login popup

require("lib/hydrate-views")

Router = require("lib/router")
window.router = new Router()
# Start the router silently because the current view should already be in the received html
Backbone.history.start({pushState: true, silent: true})

console.log('Client initialized.')
