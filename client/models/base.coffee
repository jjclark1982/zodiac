unless window?
    global._ = require('lodash')
    global.Backbone = require('backbone')

module.exports = class BaseModel extends Backbone.Model
    requirePath: module.id.replace(/^.*\/client\/|(\/index)?(\.[^\/]+)?$/g, '')
    defaultView: 'generic'
    defaultListView: 'list'
    urlRoot: null
    bucket: null
