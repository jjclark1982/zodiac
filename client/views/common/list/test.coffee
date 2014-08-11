ListView = require("./index")
BaseModel = require("lib/model")

numItems = 5

describe("ListView", ->
    beforeEach((done)->
        models = []
        for i in [0...numItems]
            model = new BaseModel()
            model.url = '/dummy-url-for-testing-only'
            models.push(model)
        @collection = new Backbone.Collection(models, {model: BaseModel})
        @view = new ListView({collection: @collection})
        @view.render(done)
    )

    afterEach(->
        @view?.remove()
    )

    it("should initialize and render without errors", ->
        expect(@view).to.be.ok
    )

    it("should show one list item for each collection item", ->
        listItems = @view.$el.children("li")
        expect(listItems.length).to.equal(numItems)
    )
)
