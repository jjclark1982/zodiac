# For any view transmitted as:
#
#     <div data-view="views/document"
#          data-model="models/document"
#          data-model-url="/documents/1">
#         Field: initial value
#     </div>
#
# This will instantiate the named view, model, and collection.

collectionsByUrl = {}
fetchCollection = (url, query, ctors)->
    if url
        collection = collectionsByUrl[url]
        if !collection
            ctors.collection ?= Backbone.Collection
            collection = new ctors.collection([], {
                url: url
                model: ctors.model or Backbone.Model
            })
            collection.query = query
            collectionsByUrl[url] = collection

            collection.fetch({data: collection.query})

    return collection

modelsByUrl = {}
fetchModel = (url, modelCtor)->
    if url
        model = modelsByUrl[url]
        if !model
            modelCtor ?= Backbone.Model
            model = new modelCtor({}, {url: url})
            modelsByUrl[url] = model

            collection = collectionsByUrl[model.urlRoot]
            if collection
                # assume the collection is already fetching the model and will merge
                collection.add(model)
            else
                model.fetch()
    return model

hydrateView = (el, parentView)->
    data = $(el).data()
    return if data['viewAttached']
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

    # fetch the latest data from the given url.
    # this is the primary way of loading non-displayed model attributes.
    options.collection = fetchCollection(data.collectionUrl, data.collectionQuery, constructors)

    options.model = fetchModel(data.modelUrl, constructors.model)

    # initialize the view, giving it a chance to register for 'change' events
    view = new constructors.view(options)

    # recursively hydrate any subviews before reaching them in a higher loop
    parentView?.registerSubview?(view)
    hydrateSubviews(el, view)
    view.attach()
    view.trigger("hydrate")
    window.views ?= {}
    window.views[view.cid] = view
    viewName = constructors.view.name
    viewName = viewName.charAt(0).toLowerCase() + viewName.slice(1)
    window.views[viewName] or= view

hydrateSubviews = (parentEl, parentView)->
    $('[data-view]', parentEl).each((i, el)->
        hydrateView(el, parentView)
    )

$(document).ready(->
    hydrateSubviews(document)
)

module.exports = hydrateView


# # Server Rendering Flow
# - load json object
# - instantiate backbone model
# - instantiate backbone view
# - get view's outerHTML
#     - get subviews' outerHTML
#     - subviews register with parent
# - stop listening
#     - remove subviews as well
# - xmit
# - find dom elements with [data-view]
#     - instantiate views for those elements
#         - instantiate subviews for their child elements
#         - store those subviews in superview.subviews{} for gc

# # Client Rendering Flow
# - instantiate model
# - instantiate view
# - add view to dom
# - render innerHTML
#     - subviews render their outerHTML
#     - subviews call superview.registerSubview()
# - attach registered subviews to their elements

# # Overall Flow

# subviews are always attached to an existing el.
# but on the client they already have data,
# whereas on the wire they need data

# so the two cases we need to consider are
# - post-transmit attach (rehydrate)
# - post-render attach (claimElement)

# if the post-render attach checked element data and filled in any missing object data,
# it could be used for both cases.
# but that would not let view.initialize() assume model and collection had been set.
# therefore they should be separate
