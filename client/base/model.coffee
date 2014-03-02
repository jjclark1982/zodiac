unless window?
    global._ = require('lodash')
    global.Backbone = require('backbone')

module.exports = class BaseModel extends Backbone.Model
    requirePath: module.id
    defaultView: 'generic'
    defaultListView: 'table'
    urlRoot: null
    bucket: null

    title: ->
        titleAtt = _.result(@, 'titleAttribute')
        name = @get("name")
        if titleAtt
            return @get(titleAtt)
        else if name
            return name
        else
            return @id
