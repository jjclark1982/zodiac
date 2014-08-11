TableView = require("./index")
BaseModel = require("lib/model")

numItems = 5
numFields = 5

describe("TableView", ->
    beforeEach((done)->
        models = []
        for i in [0...numItems]
            models.push(new BaseModel())
        @collection = new Backbone.Collection(models, {model: BaseModel})
        @fields = []
        for i in [0...numFields]
            @fields.push({
                name: "example"+i
                type: "text"
            })
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

    it("should show #{numItems+1} rows for #{numItems} items", ->
        rows = @view.$el.find("tr")
        expect(rows.length).to.equal(numItems + 1)
    )

    it("should show #{numFields+2} columns for #{numFields} fields", ->
        cells = @view.$el.find("th,td")
        rows = numItems + 1
        columnsPerRow = cells.length / rows
        expect(columnsPerRow).to.equal(numFields + 2)
    )
)
