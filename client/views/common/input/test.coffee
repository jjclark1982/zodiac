InputView = require("./index")
BaseModel = require("lib/model")

describe("InputView", ->
    beforeEach((done)->
        @model = new BaseModel()
        @field = {name: "example", type: "text"}
        @view = new InputView({model: @model, field: @field})
        @view.render(done)
    )

    afterEach(->
        @view?.remove()
    )

    it("should initialize and render without errors", ->
        expect(@view).to.be.ok
    )

    it("should have some element with a useful 'name' attribute", ->
        fieldName = @field.name
        $el = @view.$("[name='#{fieldName}']")
        expect($el[0]).to.be.ok
    )
)
