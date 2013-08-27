BaseView = require("views/base")

module.exports = class GenericView extends BaseView
    requirePath: module.id.replace(/^.*\/client\/|(\/index)?(\.[^\/]+)?$/g, '')
    template: require("./template")
    className: "generic-view"
