TableView = require("./index")
BaseModel = require("lib/model")

numItems = 5

describe("TableView", ->
    beforeEach((done)->
        models = []
        for i in [0...numItems]
            models.push(new BaseModel())
        @collection = new Backbone.Collection(models, {model: BaseModel})
        @fields = [{
            name: "example"
            type: "text"
        }]
        @view = new TableView({
            collection: @collection
            columns: @fields
        })
        @view.render(done)
    )

    afterEach(->
        @view?.remove()
    )

    it("should initialize and render without errors", ->
        expect(@view).to.be.ok
    )

    it("should show one row for each collection item, plus one header row", ->
        rows = @view.$el.find("tr")
        expect(rows.length).to.equal(numItems + 1)
    )

    it("should show one column for each field, plus one id column and one action column and", ->
        cells = @view.$el.find("th,td")
        rows = numItems + 1
        columnsPerRow = cells.length / rows
        expect(columnsPerRow).to.equal(@fields.length + 2)
    )
)
