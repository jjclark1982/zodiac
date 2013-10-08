class Router extends Backbone.Router
    routes: {
        "": "landing"
        "books(/)(?*query)": "books"
        "books/:id": "book"
    }

    books: (query="") ->
        view = @getPoppedView()
        unless view
            options = _.defaults({}, {
                viewCtor: require("views/library")
                collectionCtor: require("collections/library")
                collectionOptions: { url: document.location.pathname }
                collectionQuery: query
            })

            view = new options.viewCtor({
                collection: new options.collectionCtor([], options.collectionOptions)
            })
            view.collection.query = options.collectionQuery
            view.render()
            view.collection.fetch({data: view.collection.query})
        @setMainView(view)

    book: (id) ->
        console.log("showing model view")
        view = @getPoppedView()
        unless view
            options = _.defaults({}, {
                viewCtor: require("views/book")
                modelCtor: require("models/book")
                url: document.location.pathname
            })

            model = @mainView?.collection?.detect((m)->_.result(m,'url') is options.url)
            if model
                lightbox = true
            model ?= new options.modelCtor({}, {url: options.url})
            view = new options.viewCtor({model: model})
            view.render()
            model.fetch() if model.isNew()
        if lightbox
            console.log("lightbox happen")
            Lightbox = require("views/lightbox")
            @lightbox = new Lightbox({heroEl: view.$el})
            @lightbox.render()
            $(document.body).append(@lightbox.$el)
        else
            @setMainView(view)
        
#      routeName = Model.name
#     module.exports.route(route, routeName, (id)->
#         @showModelView({
#             viewCtor: require("views/" + Model.prototype.defaultView)
#             modelCtor: Model
#         })
#     )
        
    landing: ->
        view = @getPoppedView()
        unless view
            ActivitiesView = require("views/activities")
            view = new ActivitiesView()
            view.render()
        @setMainView(view)
   
    showModelView: (options={})->
        console.log("showing model view")
        view = @getPoppedView()
        unless view
            options = _.defaults(options, {
                viewCtor: Backbone.View
                modelCtor: Backbone.Model
                url: document.location.pathname
            })

            model = @mainView?.collection?.detect((m)->_.result(m,'url') is options.url)
            model ?= new options.modelCtor({}, {url: options.url})
            view = new options.viewCtor({model: model})
            view.render()
            model.fetch() if model.isNew()
        @setMainView(view)

    showCollectionView: (options={})->
        view = @getPoppedView()
        unless view
            options = _.defaults(options, {
                viewCtor: require("views/collection-base")
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

# modelsToRoute = [
#     'activity'
# ]

# for modelName in modelsToRoute then do (modelName)->
#     Model = require("models/#{modelName}")
#     urlRoot = Model.prototype.urlRoot.replace(/^\//, '')

#     route = urlRoot + '(/)(?*query)'
#     routeName = Model.name + "Collection"
#     module.exports.route(route, routeName, (query)->
#         @showCollectionView({
#             viewCtor: require("views/" + Model.prototype.defaultCollectionView)
#             collectionCtor: Backbone.Collection
#             collectionOptions: { url: document.location.pathname, model: Model }
#             collectionQuery: query
#         })
#     )

#     route = urlRoot + '/:id'
#     routeName = Model.name
#     module.exports.route(route, routeName, (id)->
#         @showModelView({
#             viewCtor: require("views/" + Model.prototype.defaultView)
#             modelCtor: Model
#         })
#     )