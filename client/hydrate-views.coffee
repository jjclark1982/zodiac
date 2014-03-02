# For any view transmitted as:  
#
#     ```<div data-view="views/document"  
#          data-model="models/document"  
#          data-model-url="/documents/1">  
#         Field: initial value  
#     </div>  
# ```  
# This will instantiate the named view, model, and collection.

collectionsByUrl = {}
collectionsByUrlRoot = {}
fetchCollection = (url, ctors)->
    return unless url
    collection = collectionsByUrl[url]
    unless collection
        ctors.collection ?= Backbone.Collection
        collection = new ctors.collection([], {
            url: url
            model: ctors.model or Backbone.Model
        })
        collectionsByUrl[url] = collection
        urlRoot = ctors.model?.prototype.urlRoot or url.replace(/\?.*/, '')
        collectionsByUrlRoot[urlRoot] = collection
        collection.fetch()

    return collection

modelsByUrl = {}
fetchModel = (url, modelCtor)->
    return unless url
    # TODO: support models with no urlRoot
    model = modelsByUrl[url]
    unless model
        modelCtor ?= Backbone.Model
        model = new modelCtor({}, {url: url})
        model.id = url.replace(modelCtor.prototype.urlRoot + '/', '')
        modelsByUrl[url] = model

        collection = collectionsByUrlRoot[model.urlRoot]
        if collection
            # assume the collection is already fetching the model and will merge
            # don't fire an 'add' event because the collection view is
            # presumably already populated
            collection.add(model, {silent: true})
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
    if data.collectionUrl
        options.collection = fetchCollection(data.collectionUrl, constructors)

    if data.modelUrl
        options.model = fetchModel(data.modelUrl, constructors.model)

    if data.itemView
        options.itemView = data.itemView

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
    collectionsByUrl = {}
    collectionsByUrlRoot = {}
    modelsByUrl = {}
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
