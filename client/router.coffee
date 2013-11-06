Lightbox = require("views/lightbox")


class Router extends Backbone.Router
    routes: {
        "": "landing"
    }

    landing: ->
        view = @getPoppedView()
        unless view
            ActivitySearchView = require("views/activity-search")
            view = new ActivitySearchView()
            view.render()
        @setMainView(view)
   
    showModelView: (options={})->
        view = @getPoppedView()
        unless view
            options = _.defaults(options, {
                viewCtor: Backbone.View
                modelCtor: Backbone.Model
                url: document.location.pathname
            })

            model = @mainView?.collection?.detect((m)->_.result(m,'url') is options.url)
            if model
                shouldShowModal = true
            model ?= new options.modelCtor({}, {url: options.url})
            view = new options.viewCtor({model: model})
            view.render()
            model.fetch() if model.isNew()
        if shouldShowModal
            @modalView = view
            @lightbox = new Lightbox()
            @lightbox.showView(view)
        else
            @setMainView(view)
            #TODO: have 'setMainView' and 'setModalView'

    showCollectionView: (options={})->
        view = @getPoppedView()
        unless view
            options = _.defaults(options, {
                viewCtor: require("views/list")
                collectionCtor: Backbone.Collection
                collectionOptions: { url: document.location.pathname }
            })

            view = new options.viewCtor({
                collection: new options.collectionCtor([], options.collectionOptions)
            })
            view.collection.query = options.collectionQuery
            view.render()
            view.collection.fetch({data: view.collection.query})
        @setMainView(view)

    getMainView: ->
        cid = $("#routed-content").children("[data-view]").data("cid")
        mainView = window.views[cid]
        return mainView

    setMainView: (view)->
        @lightbox?.remove()
        @modalView = null
        currentView = @mainView
        return if currentView is view

        @mainView = view
        if window.history.state?.mainView isnt view.cid
            @saveState()

        comingClass = "coming-from-future" #give me your clothes and motorcycle
        goingClass = "going-to-history" #dust in the wind, dude
        if window.history.state?.depth?
            if window.history.state.depth <= @previousDepth
                comingClass = "coming-from-history"
                goingClass = "going-to-future"
        @previousDepth = window.history.state?.depth

        # $("#routed-content").addClass("history-moving-#{direction}")
        # setTimeout(->
        #     $("#routed-content").removeClass("history-moving-#{direction}")
        #     currentView?.$el.detach()
        # , 250)

        currentView?.$el.addClass(goingClass)
        # clearTimeout(@detachTimeout)
        # @detachTimeout = setTimeout(=>
        #     $("#routed-content").children(".going-to-history").detach()
        #     $("#routed-content").children(".going-to-future").detach()
        # , 250)
        setTimeout(->
            if currentView?.$el.hasClass(goingClass)
                currentView?.$el.detach().removeClass(goingClass)
        , 1)
        view.$el.addClass(comingClass).removeClass(".going-to-history .going-to-future")
        $("#routed-content").append(view.$el)
        setTimeout(->
            view.$el.removeClass(comingClass)
        , 1)

    saveState: ->
        @initDate ?= new Date()
        @recentViews ?= []
        @previousDepth ?= 0
        window.history.replaceState?({
            initDate: @initDate
            mainView: @mainView?.cid
            depth: @recentViews.length
        })
        @recentViews.push(@mainView)

    getPoppedView: ->
        if window.history.state?.initDate?.getTime() isnt @initDate.getTime()
            return null
        else
            depth = window.history.state?.depth
            view = @recentViews[depth]
            #TODO: deal with depth underflow when going "back" to a routable, unloaded view
            return view

    invalidateCache: ->
        # if we don't have pushState, simply discard old cached views
        if !window.history.pushState? and @recentViews.length > 10
            for oldView in @recentViews.splice(0, @recentViews.length-10)
                delete window.views[oldView.cid]
                oldView.remove()
            return

        # if we are going to a new location. remove any future pages that are no longer reachable
        depth = window.history.state?.depth
        # @previousDepth = depth
        for oldView in @recentViews.splice(depth+1)
            delete window.views[oldView.cid]
            oldView.remove()

    navigateToLink: (link)->
        if link.origin is document.location.origin
            for handler in Backbone.history.handlers
                if handler.route.test(link.pathname.substr(1) + link.search)
                    @invalidateCache()
                    Backbone.history.navigate(link.pathname + link.search, {trigger: true})
                    return true
        return false

    initialize: ->
        $(document).ready(=>
            # set the initial state
            window.views ?= {}
            @initDate = new Date()
            @mainView = @getMainView()
            @saveState()

            # intercept links that can be handled by this router
            $(document).delegate("a", "click", (event)->
                event.preventDefault()
                return if event.metaKey # let users open links in new tab
                link = this
                if module.exports.navigateToLink(link)
                    event.preventDefault()
            )

            # intercept forms that can be handled by this router

            $(document).delegate("form", "click", (event)->
                $(this).data("lastClicked", event.target)
            )
            $(document).delegate("form", "submit", (event)->
                $form = $(this)
                method = $form.attr("method")
                if method and !method.match(/^get$/i)
                    return
                query = $form.serialize()
                lastClicked = $form.data("lastClicked")
                if lastClicked?.name
                    if query.length > 0
                        query += "&"
                    query += lastClicked.name + "=" + $(lastClicked).val()
                $form.removeData("lastClicked")

                link = document.createElement("a")
                link.href = this.action + "?" + query
                if module.exports.navigateToLink(link)
                    event.preventDefault()
            )
            # @on("all", ->console.log(@constructor.name,arguments, history.state))
        )
        return this

module.exports = new Router()

modelsToRoute = [
    'activity'
]

for modelName in modelsToRoute then do (modelName)->
    Model = require("models/#{modelName}")
    urlRoot = Model.prototype.urlRoot.replace(/^\//, '')

    route = urlRoot + '(/)(?*query)'
    routeName = Model.name + "Collection"
    module.exports.route(route, routeName, (query)->
        query or= document.location.search.replace(/^\?/,'')
        @showCollectionView({
            viewCtor: require("views/" + Model.prototype.defaultListView)
            collectionCtor: Backbone.Collection
            collectionOptions: { url: document.location.pathname, model: Model }
            collectionQuery: query
        })
    )

    route = urlRoot + '/:id'
    routeName = Model.name #TODO: consider how this interacts with minification
    module.exports.route(route, routeName, (id)->
        @showModelView({
            viewCtor: require("views/" + Model.prototype.defaultView)
            modelCtor: Model
        })
    )
