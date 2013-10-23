# # LoginView
# ### [GENERAL DESCRIPTION]

# *This view...*
# ***

BaseView = require("views/base")

module.exports = class LoginView extends BaseView
    requirePath: module.id
    template: require("./template")
    className: "login-view"
