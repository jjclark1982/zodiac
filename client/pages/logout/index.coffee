BaseView = require("lib/view")

module.exports = class LogoutView extends BaseView
    # A view that provides its requirePath can be re-instantiated after serialization
    requirePath: module.id

    # The CSS class for this view
    className: "logout-view"

    # BaseView's `render()` function uses the subclass's provided template
    template: require("./template")

    title: "Log Out"
