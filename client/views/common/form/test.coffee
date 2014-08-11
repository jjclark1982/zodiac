FormView = require("./index")
BaseModel = require("lib/model")

describe("FormView", ->
    beforeEach((done)->
        @model = new BaseModel()
        @model.url = '/dummy-url-for-testing-only'
        @view = new FormView({model: @model})
        @view.render(done)
    )

    afterEach(->
        @view.remove()
    )

    it("should initialize and render without errors", ->
        expect(@view).to.be.ok
    )

    it("should render a form that posts to its model's url", ->
        action = @view.$("form").attr("action")
        url = _.result(@view.model, 'url')
        expect(action).to.equal(url)
    )
)
