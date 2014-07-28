# For any view transmitted as:  
#
# ```
#     <div data-view="views/document"  
#          data-model="models/document"  
#          data-model-url="/documents/1">  
#         Field: initial value  
#     </div>  
# ```  
# This will instantiate the named view, model, and collection.

BaseView = require("lib/view")

collectionsBeingAssembled = {}
assembleCollection = (url, ctors)->
    return unless url
    collection = collectionsBeingAssembled[url]
    unless collection
        CollectionCtor = ctors.collection or Backbone.Collection
        collection = new CollectionCtor([], {
            model: ctors.collectionModel or Backbone.Model
        })
        collection.url = url
        collectionsBeingAssembled[url] = collection

    return collection

fetchModel = (el, ModelCtor)->
    data = $(el).data()
    modelType = data.model
    modelUrl = data.modelUrl

    $parent = $(el).parents("[data-collection-model='#{modelType}']").eq(0)
    collection = collectionsBeingAssembled[$parent.data('collection-url')]
    if collection
        # When a model-view is inside a collection-view with the same model type,
        # add the model to the collection, and assume the collection will fetch it and merge.
        if collection
            model = collection?.detect((m)->_.result(m,'url') is modelUrl)
            unless model
                model = ModelCtor.loadFromUrl(modelUrl, {fetch: false})
                model.needsData = true

                # Don't fire an 'add' event because the collection view is already populated.
                collection.add(model, {silent: true})
    else
        # For lone models, de-duplicate with the class cache. (TODO: garbage collect that cache)
        # If the same model is both in and out of a collection on the same page,
        # this will de-duplicate them as long as they share the same URL.
        # Dealing with aliased URLs is harder. It is recommended to transmit the canonical URL.
        model = ModelCtor.loadFromUrl(modelUrl)

    return model

hydrateView = (el, parentView)->
    data = $(el).data()
    return if data['viewAttached']

    options = {
        el: el
        tagName: el.tagName
        className: el.className
    }

    # send any data attributes not read by this function directly to the view initializer
    for key, val of data when !(key in ['view', 'model', 'collection', 'collectionModel'])
        options[key] = val

    # load the named model, view, and collection classes
    constructors = {}
    for type in ['view', 'model', 'collection', 'collectionModel']
        if data[type]
            try
                folder = type.replace(/^collectionModel/, 'model')+'s'
                constructors[type] = require("#{folder}/#{data[type]}") # eg require("views/input")
            catch e
                try
                    constructors[type] = require(data[type])
                catch e2
                    console.log("Failed to hydrate", el, ":", e)
                    return

    # fetch the latest data from the given url.
    # this is the primary way of loading non-displayed model attributes.
    if data.modelUrl
        options.model = fetchModel(el, constructors.model)

    if data.collectionUrl
        options.collection = assembleCollection(data.collectionUrl, constructors)

    # initialize the view, giving it a chance to register for 'change' events
    try
        view = new constructors.view(options)
    catch initError
        # don't let an error in one view initialization block the rest of the page loading
        console.log("Error initializing #{data.view}-view:", initError)
        $(el).addClass("error").attr("data-error", initError.message)
        view = new BaseView(options)

    # recursively hydrate any subviews before reaching them in a higher loop
    parentView?.registerSubview?(view)
    hydrateSubviews(el, view) # will populate view.collection with subviews' models
    view.collection?.fetch()
    view.attach() # will trigger render:after
    window.views ?= {}
    window.views[view.cid] = view
    viewName = constructors.view.name
    viewName = viewName.charAt(0).toLowerCase() + viewName.substring(1)
    window.views[viewName] or= view

# hydrate all subviews of a given element.
hydrateSubviews = (parentEl, parentView)->
    # when hydrating nested views, a parent will hydrate its children synchronously
    # so the children will have data['viewAttached']=true when this loop reaches them.
    # that way, a child is only ever hydrated in a context when `parentView` is acurate.
    $('[data-view]', parentEl).each((i, el)->
        hydrateView(el, parentView)
    )

$(document).ready(->
    hydrateSubviews(document)
    collectionsBeingAssembled = {}
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
