BaseView = require("lib/view")
NavigationView = require("lib/navigation")
LightboxView = require("lib/lightbox")

class Router extends Backbone.Router
    # routes: {
    #     "": "home"
    # }

    # home: ->
    #     @showPageView(require("pages/home"))

    showPageView: (ViewCtor, options={})->
        view = @getPoppedView()
        unless view
            view = new ViewCtor()
            view.render()
        @setMainView(view)

    showModelView: (options={})->
        view = @getPoppedView()
        unless view
            options = _.defaults(options, {
                viewCtor: Backbone.View
                modelCtor: Backbone.Model
                url: document.location.pathname.replace(/-[^\/]*|\.[^\/]*$/g,'') # remove slug and format
            })

            model = @mainView?.collection?.detect((m)->_.result(m,'url') is options.url)
            model ?= options.modelCtor.loadFromUrl(options.url)
            # when an aliased model receives its canonical url, update the navbar
            @listenToOnce(model, "sync", ->
                if @mainView.model is model
                    url = _.result(model, 'url')
                    if url isnt document.location.pathname
                        Backbone.history.navigate(url, {replace: true})
            )
            view = new options.viewCtor({model: model})
            view.render()
        @setMainView(view)

    showCollectionView: (options={})->
        view = @getPoppedView()
        unless view
            options = _.defaults(options, {
                viewCtor: BaseView.requireView('list')
                collectionCtor: Backbone.Collection
                collectionOptions: { url: document.location.pathname }
            })

            collection = new options.collectionCtor([], options.collectionOptions)
            collection.url = options.collectionOptions.url
            collection.query = options.collectionQuery

            view = new options.viewCtor({collection: collection})
            view.render()
            collection.fetch({data: collection.query})
        @setMainView(view)

    getMainView: ->
        mainView = @mainNavigator.$("[data-view]").data("viewAttached")
        return mainView

    setMainView: (view)->
        document.title = _.result(view, 'title') or ''
        if @isModal or (@hasPoppedState() and window.history.state.isModal)
            @modalView = view

            unless @modalNavigator
                @modalNavigator = new NavigationView({className: "left-right-navigation-view"})
            unless @lightbox
                @lightbox = new LightboxView()
                @lightbox.showView(@modalNavigator)
                @listenToOnce(@lightbox, "dismissed", ->
                    modalDepth = 1 + @modalNavigator.currentIndex
                    window.history.go(-modalDepth)
                )

            if @hasPoppedState()
                modalDepth = window.history.state.depth - @modalStartDepth
                if @modalNavigator.items.length > modalDepth
                    @modalNavigator.goToIndex(modalDepth)
                else
                    @modalNavigator.addItem(view)
            else
                @modalNavigator.addItem(view)
                @saveState()

            @modalView.delegateEvents()

            return

        @lightbox?.dismiss({silent: true})
        @lightbox = null
        # TODO: don't delete a modalNavigator that could still hold future items we want to see again
        @modalNavigator = null
        @modalView = null
        @isModal = false

        return if view is @mainView
        @mainView = view

        if @hasPoppedState()
            @mainNavigator.goToIndex(window.history.state.depth)
        else
            @mainNavigator.addItem(view, @recentViews.length)
            @saveState()

    saveState: ->
        if @isModal
            currentView = @modalView
        else
            currentView = @mainView
        @initDate ?= new Date()
        @recentViews ?= []
        @previousDepth ?= 0
        window.history.replaceState?({
            initDate: @initDate
            mainView: @mainView?.cid
            modalView: @modalView?.cid
            depth: @recentViews.length
            isModal: @isModal
        }, document.title, document.location)
        @recentViews.push(currentView)

    hasPoppedState: ->
        return (window.history.state?.initDate?.getTime() is @initDate.getTime())

    getPoppedView: ->
        if !@hasPoppedState()
            return null
        else
            depth = window.history.state?.depth
            view = @recentViews[depth]
            @isModal = window.history.state?.isModal
            #TODO: deal with depth underflow when going "back" to a routable, unloaded view
            return view

    invalidateCache: ->
        # if we don't have pushState, simply discard old cached views
        if !window.history.pushState? and @recentViews.length > 10
            for oldView in @recentViews.splice(0, @recentViews.length-10)
                oldView.remove()
            return

        # if we are going to a new location. remove any future pages that are no longer reachable
        depth = window.history.state?.depth
        # @previousDepth = depth
        for oldView in @recentViews.splice(depth+1)
            # TODO: remove the view's model from its _modelsByUrl cache
            # unless it is also in low-depth history
            oldView.remove()

    navigateToLink: (link, options={})->
        # allow links to opt out
        return false if $(link).data("skipRouter")
        # only consider links to this server
        return false if (link.origin? and link.origin isnt document.location.origin)
        # don't route hashes for now
        # TODO: investigate how well this works if pushState is not available
        return false if link.hash
        options = _.defaults(options, {
            replace: false
            trigger: true
            target: $(link).data("target")
        })
        
        for handler in Backbone.history.handlers
            if handler.route.test(link.pathname.substr(1) + link.search)
                @invalidateCache()
                if options.target is "lightbox"
                    @isModal = true
                    @modalStartDepth ?= window.history.state?.depth or @recentViews.length
                Backbone.history.navigate(link.pathname + link.search, options)
                return true
        return false

    initialize: ->
        instance = this

        # route pages
        for pageName, PageView of require("pages") then do (pageName, PageView)->
            mountPoint = (PageView.prototype?.mountPoint or pageName).replace(/^\//, '')
            instance.route(mountPoint, pageName, ()->
                instance.showPageView(PageView)
            )

        # create routes for all models that have a `urlRoot`
        for modelName, Model of require("models") then do (modelName, Model)->
            modelProto = Model.prototype
            urlRoot = modelProto.urlRoot?.replace(/^\//, '')
            return unless urlRoot

            # route lists and queries
            route = urlRoot + '(/)(?*query)'
            routeName = Model.name + "Collection"
            instance.route(route, routeName, (query)->
                document.title = modelProto.collectionTitle or ''
                query or= document.location.search.replace(/^\?/,'')
                instance.showCollectionView({
                    viewCtor: BaseView.requireView(modelProto.defaultListView)
                    collectionCtor: Backbone.Collection
                    collectionOptions: { url: document.location.pathname, model: Model }
                    collectionQuery: query
                })
            )

            # route individual items
            route = urlRoot + '/:id'
            routeName = Model.name #TODO: consider how this interacts with minification
            instance.route(route, routeName, (id)->
                instance.showModelView({
                    viewCtor: BaseView.requireView(modelProto.defaultView)
                    modelCtor: Model
                })
            )

            # route links
            for f in (modelProto.fields or []) when f.type is 'link' then do (f)->
                linkDef = f
                Target = require("models/"+linkDef.target)
                route = urlRoot + "/:id/#{linkDef.name}"
                routeName = Model.name + " link to " + linkDef.name
                instance.route(route, routeName, (id)->
                    instance.showModelView({
                        viewCtor: BaseView.requireView(Target.prototype.defaultView)
                        modelCtor: Target
                        })
                )

        $(document).ready(=>
            # create the main navigator. the modal navigator will be created on demand
            @mainNavigator = new NavigationView({
                id: "main-navigator"
                el: $("#main-navigator")
            })
            if @mainNavigator.$el.parent().length is 0
                $(document.body).append(@mainNavigator.$el)

            # set the initial state
            @initDate = new Date()
            @mainView = @getMainView()
            @saveState()
        )

        # intercept links that can be handled by this router
        $(document).delegate("a", "click", (event)=>
            return if event.metaKey # let users open links in new tab
            if @debug
                event.preventDefault(event)
                return false

            link = event.currentTarget
            if @navigateToLink(link)
                event.preventDefault(event)
        )

        # intercept forms that can be handled by this router
        $(document).delegate("form", "click", (event)->
            $(this).data("lastClicked", event.target)
        )
        $(document).delegate("form", "submit", (event)->
            form = this
            $form = $(form)
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
            link.href = form.action + "?" + query
            if instance.navigateToLink(link)
                event.preventDefault(event)
        )

        # @on("all", ->console.log(@constructor.name,arguments, history.state))
        return this

module.exports = Router
