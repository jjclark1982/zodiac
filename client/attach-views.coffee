###
For any view transmitted as:

    <div data-view="views/document" data-model="models/document" data-model-url="/documents/1">
        Field: initial value
    </div>

This will instantiate the named view, model, and collection.
###

attachView = (el, parentView)->
    data = $(el).data()
    return if data['view-attached']
    options = {el: el}

    # load the named model, view, and collection classes
    constructors = {}
    for type in ['view', 'model', 'collection', 'collectionModel']
        if data[type]
            try
                folder = type.replace(/^collectionModel/, 'model')+'s'
                constructors[type] = require("#{folder}/#{data[type]}")
            catch e
                try
                    constructors[type] = require(data[type])
                catch e2
                    console.error("Failed to hydrate", el, ":", e.message)
                    return

    if constructors.model or data.modelUrl
        constructors.model ?= Backbone.Model
        options.model = new constructors.model({}, {url: data.modelUrl})

    if constructors.collection or data.collectionUrl
        constructors.collection ?= Backbone.Collection
        options.collection = new constructors.collection([], {
            url: data.collectionUrl
            model: constructors.collectionModel
        })
        options.collection.query = data.collectionQuery

    # initialize the view, giving it a chance to register for 'change' events
    view = new constructors.view(options)
    parentView?.registerSubview?(view)
    attachSubviews(el, view)
    view.postRender?()
    # view.attach?()
    # view.hydrate?()
    window.cachedViews ?= {}
    window.cachedViews[view.cid] = view

    # fetch the latest data from the given url.
    # this is the primary way of loading non-displayed model attributes.
    if data.collectionUrl
        options.collection.fetch({data: options.collection.query})

    # if a newly created model is part of a collection,
    # assume that is because the collection is already being fetched
    if data.modelUrl and !options.model.collection
        setTimeout(->
            options.model.fetch()
        , 1)

attachSubviews = (parentEl, parentView)->
    $('[data-view]', parentEl).each((i, el)->
        attachView(el, parentView)
    )

$(document).ready(->
    attachSubviews(document)
)

module.exports = attachView

###

instead of doing all elements on the page at this level
and matching parents/children through cachedViews[],
we could have the attach/hydrate method look for child views that are not yet attached,
and then attach them recursively


in-browser flow:
init
preRender
getInnerHTML
render
postRender

transport flow:
init
getInnerHTML
getOuterHTML
(xmit)
attach
(recursively attach children)
postRender





TODO: consider moving this functionality into BaseView constructor
so that whenever we initialize a view with a tagged element
it will automatically do these things
###

# constructor: (options = {})->
#     if options.el?
#         data = $(options.el).data()
#         constructors = {
#             model: Backbone.Model
#             collection: Backbone.Collection
#         }
#         for type of constructors
#             if data[type]
#                 try
#                     constructors[type] = require(data[type])
#                 catch e
#                     console.error("Unknown #{type} type '#{data[type]}'")

#         if data.model or data.modelUrl
#             options.model = new constructors.model({}, {url: data.modelUrl})
#             options.model.fetch() if data.modelUrl

#         if data.collection or data.collectionUrl
#             options.collection = new constructors.collection([], {url: data.collectionUrl})
#             options.collection.fetch() if data.collectionUrl

#     if options.model?
#         @listenTo(options.model, 'request', ->
#             @$el.addClass("loading")
#         )
#         @listenTo(options.model, 'sync', ->
#             @$el.removeClass("loading")
#         )

#     super(arguments...)
#     if options.el?
#         @attach(options.el)
