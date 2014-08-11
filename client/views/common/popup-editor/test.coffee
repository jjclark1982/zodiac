PopupEditorView = require("./index")
BaseModel = require("lib/model")

describe("PopupEditorView", ->
    beforeEach((done)->
        @model = new BaseModel
        @view = new PopupEditorView({
            model: @model
            fieldName: "example"
        })
        @view.render(done)
    )

    afterEach(->
        @view?.remove()
    )

    it("should initialize and render without errors", ->
        expect(@view).to.be.ok
    )
)
