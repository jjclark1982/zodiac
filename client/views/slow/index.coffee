BaseView = require("views/base")

delay = 1

module.exports = class SlowView extends BaseView
    requirePath: module.id.replace(/^.*\/client\/|(\/index)?(\.[^\/]+)?$/g, '')
    # template: require("./template")
    className: "slow-view"

    getInnerHTML: (callback)->
        delay++
        setTimeout(=>
            context = _.result(@, 'templateContext')
            @template(context, callback)
        , 250*delay)
        setTimeout(->
            delay = 1
        , 3000)

    template: (chunk, context)->
        tmpl = require("./template")

        delay++
        setTimeout(->
            delay = 1
        , 3000)
        return chunk.map((branch)->
            setTimeout(->
                tmpl(branch, context).end()
            , 250*delay)
        )
