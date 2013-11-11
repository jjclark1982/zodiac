unless window?
    global._ = require('lodash')
    global.Backbone = require('backbone')

module.exports = class BaseModel extends Backbone.Model
    requirePath: module.id
    defaultView: 'generic'
    defaultListView: 'list'
    urlRoot: null
    bucket: null

    title: ->
        titleAtt = _.result(@, 'titleAttribute')
        if titleAtt
            return @get(titleAtt)
        else
            return @id

